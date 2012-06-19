source :rubygems

gem "thin"
gem "system_timer"

group :database do
  gem 'uuidtools'
  gem 'data_mapper', :require=>'dm-core'
  gem 'dm-validations'
  gem 'dm-migrations'
  gem 'dm-timestamps'
  gem 'dm-mysql-adapter'
  gem 'dm-sqlite-adapter'
end

group :web do
  gem 'sinatra'
  gem 'haml'
  gem 'rack-flash3', :require=>"rack-flash"
  #  gem 'sinatra-xsendfile'
  gem "json","~> 1.6.1" ,:require=> 'json/ext'
  gem 'omniauth'
  gem 'omniauth-twitter',  :git => 'https://github.com/arunagw/omniauth-twitter.git'
  gem 'omniauth-github',   :git => 'git://github.com/intridea/omniauth-github.git'
  gem 'omniauth-openid',   :git => 'git://github.com/intridea/omniauth-openid.git'
  gem 'omniauth-facebook', :git => "git://github.com/mkdynamic/omniauth-facebook.git"
end
