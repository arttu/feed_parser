require 'open-uri'
require 'nokogiri'

class FeedParser

  VERSION = "0.2.0"

  def initialize(opts)
    @url = opts[:url]
    @@sanitizer = (opts[:sanitizer] || SelfSanitizer.new)
    @@fields_to_sanitize = (opts[:fields_to_sanitize] || [:content])
    self
  end

  def self.sanitizer
    @@sanitizer
  end

  def self.fields_to_sanitize
    @@fields_to_sanitize
  end

  def parse
    @feed ||= Feed.new(@url)
  end
end

require 'feed_parser/dsl'
require 'feed_parser/feed'
require 'feed_parser/feed_item'
require 'feed_parser/self_sanitizer'
