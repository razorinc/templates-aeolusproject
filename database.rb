# -*- coding: utf-8 -*-

Bundler.require(:database)
require 'dm-migrations/migration_runner'

DataMapper::Logger.new(STDOUT, :debug) unless ENV['RACK_ENV'] == "production"
DataMapper.setup(:default, 'sqlite::memory:') if ENV['RACK_ENV']=="test"
DataMapper.setup(:default, "sqlite:////#{Dir.pwd}/templates.sqlite3")

class User
  include DataMapper::Resource

  property :id, String, :key => true, :required => true,
                        :default => proc { UUIDTools::UUID.random_create }
  # Each user may log in using different methods:
  has n, :authentications
  has n, :entries

end

class Authentication
  include DataMapper::Resource

  belongs_to :user, :key => true

  # Authentication provider:
  property :provider, String, :key => true

  # User ID allocated by that provider:
  property :uid, String, :length => 240

  # User name and email:
  property :user_name,  String, :length => 240
  property :user_email, String, :length => 240, :index => true
end

class Entry
  include DataMapper::Resource

  property :id, Serial

  property :name, String, :key => true,
                          :required => true,
                          :default =>proc { UUIDTools::UUID.random_create }
  property :rating, Decimal, :default => 0 , :writer=> :protected
  property :sum,    Integer, :default => 0
  property :votes,  Integer, :default => 0
  timestamps :at

  has n, :comments
  has 1, :deployable
  has 1, :image
  belongs_to :user

=begin
  has n, :post_tags
  has n, :tags, :through => :post_tags

  def tag_list
    tags.all.map { |t| t.name }.join(', ')
  end

  def tag_list=(list)
    list.each do |tag|
      new_tag = Tag.first_or_create(:name => tag)
      tags << new_tag
    end
  end
=end

  def self.popular(limit = 5)
    all(:rating.gt=>3, :order => [ :rating.desc ], :limit=>limit)
  end

  def self.last_inserts(limit = 5)
    all(:order=>[ :created_at.desc ],:limit=>limit)
  end

end
class Deployable
  include DataMapper::Resource

  property :id, Serial
  property :content, Text

end

class Image
  include DataMapper::Resource

  property :id, Serial
  property :content, Text
end

class Comment
  include DataMapper::Resource

  property :id, Serial
  property :text, Text

  belongs_to :entry
end

# Adding the tagging feature - Start
class EntryTag

  include DataMapper::Resource

  property :tag_id,   Integer, :key => true
  property :entry_id, Integer, :key => true

  belongs_to :entry
  belongs_to :tag

end

class Tag

  include DataMapper::Resource

  property :id,   Serial
  property :name, String, :required=>true, :unique => true, :unique_index => true
  has n, :entry_tags

  has n, :entries,
    :through => :entry_tags
end

# - END

# Migration to create the Trigger
migration 1, :create_people_table do
  up do
    execute <<-EOF
delimiter #

create trigger entry_vote_after_ins_trig after insert on image_vote
for each row
begin
 update entry set
    votes = votes + 1,
    total_score = score + new.score,
    rating = total_score / votes
 where
    entry_id = new.entry_id;
end#

delimiter ;
    EOF
  end
  down do
    execute "DROP TRIGGER entry_vote_after_ins_trig"
  end
end
# End

# @mfojtik: This will erase the database everytime you start a server :)
DataMapper.finalize
DataMapper.auto_migrate!
DataMapper.auto_upgrade!
