# FeedParser

Rss and Atom feed parser built on top of Nokogiri. Supports custom sanitizers.

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

## Running tests

Install dependencies by running `bundle install`.

Run rspec tests:

    $ bundle exec rspec

## Contributing

Fork, hack, push, create a pull request.
