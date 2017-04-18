# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'thor', '~> 0.19.4'

# Create, read and manipulate Git repositories by wrapping system calls to the git binary
gem 'git-ng', '~> 1.4'

gem 'byebug', require: true # , group :development
