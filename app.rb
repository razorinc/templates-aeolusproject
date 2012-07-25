# -*- coding: utf-8 -*-

unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require 'bundler/setup'
Bundler.require(:web)
require_relative 'configuration'
require_relative 'helpers'
require_relative 'database'

class AppBase < Sinatra::Base
  set :static, true
  set :public_folder, File.join(File.dirname(__FILE__),'public') # was Proc.new
  configure :development do
    set :session_secret, "ilovesinatra"
  end

  enable :sessions
  use Rack::Session::Cookie
  use Rack::Flash, :sweep => true
  helpers Sinatra::AuthHelpers
  helpers Sinatra::ViewHelpers
  register Sinatra::Partial

  set :current_revision, %x{git rev-parse HEAD} 

  set(:auth) do |bool|
    condition do
      puts "i'm :auth and i'm currently running!"
      unless authenticated?
        puts "and I can tell you're not currently authenticated!"
        flash[:error] = "You're currently not logged in"
        redirect "/", 303
      end
    end
  end

end

class Application < AppBase
  set :views, File.join(File.dirname(__FILE__),'views', name.downcase)

  before do
    puts "authenticated? = #{authenticated?}"
    puts "return_to= #{session[:return_to]}"
    session[:return_to] = request.referer || "/"
  end

  not_found do
    haml(["%h1 Four Oh Four!",
          "%h2 Doh!"
         ].join('\n'), :layout=>false
         )
  end

  get '/' do
    puts "DEBUG: #{session.inspect}" unless ENV['DEBUG_IT'].nil?
    # Default will be 5
#    @last_inserted = 
#    # Default will be 5
#    @most_requested = Entry.popular
    haml(:index, :locals => {:last_inserted=>Entry::last_inserts(10),
                      :most_requested=>Entry::popular(10),
                      :current_user => User::first(session[:user_id])
                      })
  end

  get '/entry/list' do
    haml(:list, :locals=>{:entries=>Entry::all})
  end

  get '/entry/new', :auth=>true do
#    (flash[:error]="You're not authenticated";
#     redirect to("/")) unless authenticated?
    haml(:new, :locals=>{:entry=>Entry.bogus}) #if authenticated?
  end

  post '/entry', :auth=>true do
    # a new entry has
    # username, title
    # image template,deployable template,<< tags >>
    current_user = User::first(:id=>session[:user_id])
    entry = current_user.entries.new
    entry.image = Image.new(:content=>params[:image])
    entry.deployable = Deployable.new(:content=>params[:deployable])
    entry.tag_list = params[:tag_list].split(/\s?,\s?/).map(&:capitalize)
    begin
      entry.save
    rescue DataMapper::SaveFailureError => e
      puts "[DEBUG] Your entry wasn't saved: #{entry.errors.values.join(', ')}"
      flash[:error] = "Your entry wasn't saved<BR/>#{entry.errors.values.join(', ')} ";
    rescue StandardError => e
      flash[:error] ="Got an error trying to save the article #{e.to_s}"
     redirect to("/")
    end
    
    flash[:notice] = "Your entry got added"
    redirect to("/entry/#{entry.name}")
  end

  get '/entry/:uuid' do
    entry ||= Entry::first(:name=>params[:uuid])
    (flash[:error] = "The element wasn't found";
     redirect to(session[:return_to])) if entry.nil?
    haml :show_entry, :locals=>{:entry=>entry,
                                :current_user=>(User::first(
                                             :id=>session[:user_id]))
                                }
  end

  get '/entry/:uuid/edit', :auth=>true do |uuid|
    current_user = User::first(:id=>session[:user_id])
    entry = current_user.entries.first(:name=>uuid)
    haml :edit, :locals=>{:entry=> entry
                         } if current_user.is_owner?(entry.uuid)
  end

  put '/entry', :auth=>true do
    current_user = User::first(:id=>session[:user_id])
    entry = current_user.entries.first(:name=>params[:uuid])
    entry.update(:name=>params[:name], 
                  :"deployable.content"=>params[:deployable],
                  :"image.content"=>params[:image]
                )
    halt 403 unless current_user.is_owner?(entry)
  end

  get %r{/entry/([^\/?#]+)/raw/(image|deployable).xml} do |entry, kind|
    element ||= Entry::first(:name=>entry)
    halt 404 if element.nil?

    case kind
      when "image"
        @output=element.image.content || "ERROR"
      when "deployable"
        @output=element.deployable.content || "ERROR"
      else
        halt 404
    end
    "#{kind} = #{entry}" unless ENV['DEBUG_IT'].nil?
    content_type "text/xml"
    @output
  end

end

class Oauth < AppBase
  require 'openid/store/filesystem'

  use Rack::Session::Cookie
  use OmniAuth::Builder do
    provider :openid, :store => OpenID::Store::Filesystem.new('./tmp')
    provider :twitter,  ENV['TWITTER_KEY'],  ENV['TWITTER_SECRET']
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    provider :github,   ENV['GITHUB_KEY'],   ENV['GITHUB_SECRET']
  end

  before do
    puts "Oauth: #{request.referer}"
  end

  get '/' do
    redirect to("/")
    # <<-HTML
    # <a href='/authenticate/auth/twitter'>Sign in with Twitter</a>
    # <a href='/auth/github'>Sign in with Github</a>

    # <form action='/test/auth/open_id' method='post'>
    #   <input type='text' name='identifier'/>
    #   <input type='submit' value='Sign in with OpenID'/>
    # </form>
    # HTML
  end

  get '/auth/:name/callback' do
    puts params[:name]
    session[:return_to] = request.referer || "/"
    authenticate
    redirect to(session[:return_to])
  end

  get '/auth/failure' do
    flash[:error]="Authentication failure"
    redirect to('/')
  end

  get '/sign_out' do
#    session[:user_id]=nil
    session.clear
    redirect to("/")
  end

end

class Api < Sinatra::Base

  get '/' do
    "I was too lazy for this...Nothing here yet!"
  end

  get '/search' do
    halt 404 if params[:q].nil?
    Entry.search(params[:q].split(/\s?,\s?/).map(&:capitalize))
  end
end
