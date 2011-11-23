class FeedParser
  class Feed
    attr_reader :type

    def initialize(feed_url)
      @feed = Nokogiri::XML(open(feed_url))
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
  end
end
