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

  enable :sessions
  use Rack::Session::Cookie
  use Rack::Flash, :sweep => true
  helpers Sinatra::AuthHelpers
end

class Application < AppBase
  set :views, File.join(File.dirname(__FILE__),'views', name.downcase)

  before do
    puts "authenticated? = #{authenticated?}"
    puts "return_to= #{session[:return_to]}"
    puts %x{git rev-parse HEAD} if ENV['RACK_ENV'] == "development"
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
    @last_inserted = Entry.last_inserts
    # Default will be 5
    @most_requested = Entry.popular
    haml :index
  end

  get '/entry/new' do
    (flash[:error]="You're not authenticated";
     redirect to("/")) unless authenticated?
    haml(:new) if authenticated?
  end

  post '/entry/new' do
    # a new entry has:
    # username, title
    # image template,deployable template,<< tags >>
    user = User::first(:id=>session[:user_id])
    entry = user.entries.create!
    entry.image = Image.create!(:content=>params[:image])
    entry.deployable = Deployable.create!(:content=>params[:deployable])
    entry.save!
    (flash[:notice] = "Your entry got added";
     redirect to("/entry/#{entry.name}")
     ) if entry.saved?
    (flash[:error]  = "Your entry wasn't saved";
     redirect to("/")
     ) unless entry.saved?
  end

  get '/entry/:uuid' do
    entry ||= Entry::first(:name=>params[:uuid])
    (flash[:error] = "The element wasn't found";
     redirect to(session[:return_to])) if entry.nil?
    haml :show_entry
  end


  get %r{/entry/([^\/?#]+)/raw/(image|deployable).xml} do |entry, kind|
    element ||= Entry::first(:name=>params[:id])
    halt 404 if element.nil?

    case kind
      when "image"
        entry.image.content || "ERROR"
      when "deployable"
        entry.deployable.content || "ERROR"
      else
        halt 404
    end
    "#{kind} = #{entry}" unless ENV['DEBUG_IT'].nil?
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
    redirect to(session[:return_to])
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
    session[:return_to] = request.referer || "/"
    session[:user_id]=nil
    puts session.inspect
    redirect to(session[:return_to])
  end

end

class Api < Sinatra::Base

  get '/' do
    "I was too lazy for this...Nothing here yet!"
  end
end
