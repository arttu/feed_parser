# FeedParser

Rss and Atom feed parser built on top of Nokogiri. Supports custom sanitizers.

## Build Status

[![Build Status](https://secure.travis-ci.org/arttu/feed_parser.png)](http://travis-ci.org/arttu/feed_parser)

FeedParser gem is tested on Ruby 1.8.7, 1.9.2, 1.9.3 and JRuby.

## Install

Add to Gemfile

    gem "feed_parser"

## Usage

    # the most basic use case
    fp = FeedParser.new(:url => "http://example.com/feed/")
    # with sanitizer
    fp = FeedParser.new(:url => "http://example.com/feed/", :sanitizer => MyBestestSanitizer.new)
    # sanitizing custom field set
    fp = FeedParser.new(:url => "http://example.com/feed/", :sanitizer => MyBestestSanitizer.new, :fields_to_sanitize => [:title, :content])
    
    # parse the feed
    feed = fp.parse
    
    # using parsed feed in your code
    feed.as_json
    # => {:title => "Feed title", :url => "http://example.com/feed/", :items => [{:guid => , :title => , :author => ...}]}
    
    feed.items.each do |feed_item|
      pp feed_item
    end

    # you can also pass http options to be used for the connection
    # for available options, check out the OpenURI documentation: http://apidock.com/ruby/OpenURI
    fp = FeedParser.new(:url => "http://example.com/feed/", :http => {:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE})

If the fetched XML is not a valid RSS or an ATOM feed, a FeedParser::UnknownFeedType is raised in FeedParser#parse.

## Running tests

Install dependencies by running `bundle install`.

Run rspec tests:

    $ bundle exec rake spec

## Contributing

Fork, hack, push, create a pull request.
