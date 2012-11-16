require 'open-uri'
require 'nokogiri'

class FeedParser

  USER_AGENT = "Ruby / FeedParser gem"

  class FeedParser::UnknownFeedType < Exception ; end
  class FeedParser::InvalidURI < Exception ; end

  def initialize(opts)
    @url = opts[:url]
    @http_options = {"User-Agent" => FeedParser::USER_AGENT}.merge(opts[:http] || {})
    @@sanitizer = (opts[:sanitizer] || SelfSanitizer.new)
    @@fields_to_sanitize = (opts[:fields_to_sanitize] || [:content])
    @feed_xml = opts[:feed_xml]
    self
  end

  def self.sanitizer
    @@sanitizer
  end

  def self.fields_to_sanitize
    @@fields_to_sanitize
  end

  def parse
    if @feed_xml
      feed_xml = @feed_xml
    else
      feed_xml = open_or_follow_redirect(@url)
    end
    @feed ||= Feed.new(feed_xml)
    feed_xml.close! if feed_xml.class.to_s == 'Tempfile'
    @feed
  end

  private

  def open_or_follow_redirect(feed_url)
    uri = URI.parse(feed_url)

    if uri.userinfo
      @http_options[:http_basic_authentication] = [uri.user, uri.password].compact
      uri.userinfo = uri.user = uri.password = nil
    end

    @http_options[:redirect] = true if RUBY_VERSION >= '1.9'

    if ['http', 'https'].include?(uri.scheme)
      open(uri.to_s, @http_options)
    else
      raise FeedParser::InvalidURI.new("Only URIs with http or https protocol are supported")
    end
  rescue RuntimeError => ex
    redirect_url = ex.to_s.split(" ").last
    if URI.parse(feed_url).scheme == "http" && URI.parse(redirect_url).scheme == "https"
      open_or_follow_redirect(redirect_url)
    else
      raise ex
    end
  end
end

require 'feed_parser/dsl'
require 'feed_parser/feed'
require 'feed_parser/feed_item'
require 'feed_parser/self_sanitizer'
