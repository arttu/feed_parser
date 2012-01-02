class FeedParser
  class Feed
    attr_reader :type

    def initialize(feed_url)
      raw_feed = open_or_follow_redirect(feed_url)
      @feed = Nokogiri::XML(raw_feed)
      @feed.remove_namespaces!
      @type = (@feed.search('rss')[0] && :rss || :atom)
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
      parsed_url = parse_url(feed_url)

      connection_options = {"User-Agent" => FeedParser::USER_AGENT}
      connection_options[:http_basic_authentication] = parsed_url[:basic_auth] if parsed_url[:basic_auth]

      connection_options[:redirect] = true if RUBY_VERSION >= '1.9'

      if parsed_url[:protocol]
        open(parsed_url[:url], connection_options)
      else
        open(parsed_url[:url])
      end
    rescue RuntimeError => ex
      redirect_url = ex.to_s.split(" ").last
      if URI.split(feed_url).first == "http" && URI.split(redirect_url).first == "https"
        open_or_follow_redirect(redirect_url)
      else
        raise ex
      end
    end

    def parse_url(feed_url)
      protocol, auth, *the_rest = URI.split(feed_url)
      # insert a question mark in the beginning of query part of the uri
      the_rest[-2].insert(0, '?') if the_rest[-2].is_a?(String)
      url = (protocol && [protocol, the_rest.join].join('://') || the_rest.join)
      basic_auth = auth.split(':') if auth
      {:protocol => protocol, :url => url, :basic_auth => basic_auth}
    end
  end
end
