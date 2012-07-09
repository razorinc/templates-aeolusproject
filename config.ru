unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require 'bundler/setup'
Bundler.require
require './app.rb'

map '/' do
  # @mfojtik: class name 'Application' could be ambithius, Sinatra already has class with that name.
  run Application
end

# Should support api
map '/api' do
  run Api
end

map '/authenticate' do
  run Oauth
end
