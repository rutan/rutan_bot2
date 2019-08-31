# frozen_string_literal: true

ruby '2.6.3'
source 'https://rubygems.org'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'rake'

gem 'mobb'
gem 'repp'

gem 'activerecord'

gem 'slack-ruby-client'

group :production do
  gem 'pg'
end

group :development do
  gem 'sqlite3'
  gem 'pry'
end
