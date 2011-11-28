class FeedParser
  class Feed
    attr_reader :type

    def initialize(feed_url)
      parsed_url = parse_url(feed_url)
      @feed = Nokogiri::XML(open(parsed_url[:url], :http_basic_authentication => parsed_url[:basic_auth]))
      @feed.remove_namespaces!
      @type = (@feed.search('rss')[0] && :rss || :atom)
      self
    end

    def title
      @title = @feed.xpath(Dsl[@type][:title]).text
    end

    def url
      _url = @feed.xpath(Dsl[@type][:url]).text
      @url = (!_url.nil? && _url.length > 0 && _url || @feed.xpath(Dsl[@type][:url]).attribute("href").text)
    end

    def items
      klass = (@type == :rss && RssItem || AtomItem)

      @items ||= @feed.xpath(Dsl[@type][:item]).map do |item|
        klass.new(item)
      end
    end

    def as_json
      {
        :title => title,
        :url => url,
        :items => items.map(&:as_json)
      }
    end

    private
    def parse_url(feed_url)
      protocol, auth, *the_rest = URI.split(feed_url)
      # insert a question mark in the beginning of query part of the uri
      the_rest[-2].insert(0, '?') if the_rest[-2].is_a?(String)
      url = (protocol && [protocol, the_rest.join].join('://') || the_rest.join)
      basic_auth = auth.split(':') if auth
      {:url => url, :basic_auth => basic_auth}
    end
  end
end
