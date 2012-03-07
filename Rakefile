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
