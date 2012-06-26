class FeedParser
  class Feed
    attr_reader :type

    def initialize(feed_url, http_options = {})
      @http_options = http_options
      raw_feed = open_or_follow_redirect(feed_url)
      @feed = Nokogiri::XML(raw_feed)
      @feed.remove_namespaces!
      @type = ((@feed.xpath('/rss')[0] && :rss) || (@feed.xpath('/feed')[0] && :atom))
      raise FeedParser::UnknownFeedType.new("Feed is not an RSS feed or an ATOM feed") unless @type
      self
    end

    def title
      @title = @feed.xpath(Dsl[@type][:title]).text
    end

    def url
      _url = case @type
        when :rss
          @feed.xpath(Dsl[@type][:url])
        when :atom
          @feed.xpath(Dsl[@type][:url]).first && @feed.xpath(Dsl[@type][:url]).attribute("href") ||
          @feed.xpath(Dsl[@type][:alternate_url]).first && @feed.xpath(Dsl[@type][:alternate_url]).attribute("href")
        else
          nil
      end
      @url = _url && _url.text || ""
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

    # Some feeds
    def open_or_follow_redirect(feed_url)
      parsed_url = URI.parse(feed_url)

      connection_options = {"User-Agent" => FeedParser::USER_AGENT}
      connection_options.merge!(@http_options)
      if parsed_url.userinfo
        connection_options[:http_basic_authentication] = [parsed_url.user, parsed_url.password].compact
        parsed_url.userinfo = parsed_url.user = parsed_url.password = nil
      end

      connection_options[:redirect] = true if RUBY_VERSION >= '1.9'

      if parsed_url.scheme
        open(parsed_url.to_s, connection_options)
      else
        open(parsed_url.to_s)
      end
    rescue RuntimeError => ex
      redirect_url = ex.to_s.split(" ").last
      if URI.split(feed_url).first == "http" && URI.split(redirect_url).first == "https"
        open_or_follow_redirect(redirect_url)
      else
        raise ex
      end
    end
  end
end
