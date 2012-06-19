require 'bundler/setup'
Bundler.require
require 'app'

map '/' do
  run Application
end

map '/api' do
# Should support api
  run Api
end

map '/authenticate' do
  run Oauth
end
