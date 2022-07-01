# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.3'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'rake'

gem 'mobb'
gem 'repp'

gem 'activerecord'

gem 'rest-client'
gem 'slack-ruby-client'
gem 'async-websocket', '~> 0.8.0'
gem 'twitter'

group :production do
  gem 'pg'
end

group :development do
  gem 'sqlite3'
  gem 'pry'
end
