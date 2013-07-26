# FeedParser

Rss and Atom feed parser built on top of Nokogiri. Supports custom sanitizers.

## Build Status

[![Build Status](https://secure.travis-ci.org/arttu/feed_parser.png)](http://travis-ci.org/arttu/feed_parser)

FeedParser gem is tested on Ruby 1.9.3 and 2.0.0.
1.8.7 should work with Nokogiri < 1.6.0.

## Install

Add to Gemfile

    gem "feed_parser"

## Usage

#### Parse from URL

    fp = FeedParser.new(:url => "http://example.com/feed/")
    feed = fp.parse

Optionally pass HTTP options, see more from the OpenURI documentation: http://apidock.com/ruby/OpenURI

    fp = FeedParser.new(:url => "http://example.com/feed/", :http => {:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE})

#### Parse from an XML string

    fp = FeedParser.new(:feed_xml => "<rss>...</rss>")
    feed = fp.parse

#### Use sanitizer

    fp = FeedParser.new(:url => "http://example.com/feed/", :sanitizer => MyBestestSanitizer.new)
    # sanitizing custom field set
    fp = FeedParser.new(:url => "http://example.com/feed/", :sanitizer => MyBestestSanitizer.new, :fields_to_sanitize => [:title, :content])

#### Using parsed feed in your code

    feed.as_json
    # => {:title => "Feed title", :url => "http://example.com/feed/", :items => [{:guid => , :title => , :author => ...}]}
    
    feed.items.each do |feed_item|
      pp feed_item
    end

If the XML is not a valid RSS or an ATOM feed, a FeedParser::UnknownFeedType is raised in FeedParser#parse.

## Running tests

Install dependencies:

    $ gem install bundler
    $ bundle install

Run rspec tests:

    $ bundle exec rake spec

## Contributing

Fork, hack, push, create a pull request.
