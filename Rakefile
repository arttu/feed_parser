require 'rubygems'
require 'rake'
require 'bundler'

begin
  require 'rspec'
rescue Bundler::BundlerError => e
  $stderr.puts "Run `bundle install` to install rspec gem"
  exit e.status_code
end

require 'rspec/core/rake_task'

desc "Run spec tests"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Default: Run specs"
task :default => :spec

namespace :rubies do
  rvm_rubies_command = "rvm 1.8.7-p302@feed_parser,1.9.3-p194@feed_parser do"

  desc "Update dependencies for all Ruby versions"
  task :update_dependencies do
    system("#{rvm_rubies_command} bundle install")
    system("#{rvm_rubies_command} bundle update")
  end

  desc "Run tests with Ruby versions 1.8.7 and 1.9.3"
  task :spec do
    system("#{rvm_rubies_command} bundle exec rake spec")
  end
end
