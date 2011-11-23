# feed_parser.gemspec
# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require 'feed_parser/version'

Gem::Specification.new do |s|
  s.name        = 'feed_parser'
  s.version     = FeedParser::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Arttu Tervo']
  s.email       = ['arttu.tervo@gmail.com']
  s.homepage    = 'http://github.com/arttu/feed_parser'
  s.summary     = %q{Rss and Atom feed parser}
  s.description = %q{Rss and Atom feed parser with sanitizer support built on top of Nokogiri.}

  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rspec-rails', '~> 2.6'

  s.extra_rdoc_files = %w[README.md Changelog.md]
  s.require_paths = %w[lib]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
end
