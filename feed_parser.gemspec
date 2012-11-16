# feed_parser.gemspec
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'feed_parser'
  s.version     = "0.3.4"
  s.authors     = ['Arttu Tervo']
  s.email       = ['arttu.tervo@gmail.com']
  s.homepage    = 'https://github.com/arttu/feed_parser'
  s.summary     = %q{Rss and Atom feed parser}
  s.description = %q{Rss and Atom feed parser with sanitizer support built on top of Nokogiri.}

  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rake', '>= 0.9'
  s.add_development_dependency 'rspec', '>= 2.10'

  s.extra_rdoc_files = %w[README.md]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
end
