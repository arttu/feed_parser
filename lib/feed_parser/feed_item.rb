class FeedParser
  class FeedItem
    attr_reader :type

    def initialize(item)
      @guid = item.xpath(Dsl[@type][:item_guid]).text
      @title = item.xpath(Dsl[@type][:item_title]).text
      @author = item.xpath(Dsl[@type][:item_author]).text
      @content = item.xpath(Dsl[@type][:item_content]).text
      self
    end

    def method_missing(method_id)
      if self.instance_variables.map(&:to_sym).include?("@#{method_id}".to_sym)
        if FeedParser.fields_to_sanitize.include?(method_id)
          FeedParser.sanitizer.sanitize(self.instance_variable_get("@#{method_id}".to_sym))
        else
          self.instance_variable_get("@#{method_id}".to_sym)
        end
      else
        super
      end
    end

    def as_json
      {
        :guid => guid,
        :link => link,
        :title => title,
        :categories => categories,
        :author => author,
        :content => content
      }
    end
  end

  class RssItem < FeedItem
    def initialize(item)
      @type = :rss
      super
      @link = item.xpath(Dsl[@type][:item_link]).text
      @categories = item.xpath(Dsl[@type][:item_categories]).map{|cat| cat.text}
    end
  end

  class AtomItem < FeedItem
    def initialize(item)
      @type = :atom
      super
      @link = item.xpath(Dsl[@type][:item_link]).attribute("href").text
      @categories = item.xpath(Dsl[@type][:item_categories]).map{|cat| cat.attribute("term").text}
    end
  end
end
