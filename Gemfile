source 'https://rubygems.org'

ruby '2.3.3'

gem 'api-pagination'
gem 'apipie-rails'
gem 'audited-activerecord', '~> 3.0'
gem 'aws-sdk', '~> 2'
gem 'browser'
gem 'exception_notification'
gem 'gon'
gem 'haml-rails', '~> 0.4.0'
gem 'httparty'
gem "jquery-fileupload-rails"
gem 'jquery-rails'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'nokogiri'
gem 'pg'
gem 'pg_search'
gem 'rails', '3.2.22.5'
gem 'rack-pratchett'
gem 'redis-rails'
gem 'resque'
gem 'resque_mailer'
gem 'resque-retry'
gem 'resque-web', '0.0.8', require: 'resque_web'
gem 'sanitize'
gem 'sass-rails'
gem 'select2-rails'
gem 'test-unit', '~> 3.0' # required by Heroku for production console
gem 'tinymce-rails'
gem 'will_paginate', '~> 3.0.6'
gem 'bootstrap-sass', '~> 3.1.1.0'
gem "font-awesome-rails"

group :production do
  gem 'puma'
  gem 'rack-cors'
  gem 'rack-timeout'
  gem 'rails_12factor'
  gem 'tunemygc'
end

group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
end

group :development, :test do
  gem 'byebug'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'rake', '10.4.2'
  gem 'seed_dump', '0.5.3'
  gem 'thin'
  gem 'rspec-rails'
end

group :test do
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem 'factory_girl_rails'
  gem 'json', '1.8.2'
  gem 'resque_spec'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
