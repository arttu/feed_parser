class FeedParser
  class Dsl
    def self.[](type)
      send(type)
    end
    def self.rss
      {
        :title => "/rss/channel/title",
        :url => "/rss/channel/link",
        :item => "/rss/channel/item",
        :item_guid => "guid",
        :item_link => "link",
        :item_title => "title",
        :item_published => "pubDate",
        :item_categories => "category",
        :item_author => "creator",
        :item_description => "description",
        :item_content => "encoded",
      }
    end
    def self.atom
      {
        :title => "/feed/title",
        :url => "/feed/link[@rel='self']",
        :alternate_url => "/feed/link[@rel='alternate']",
        :item => "/feed/entry",
        :item_guid => "id",
        :item_link => "link",
        :item_title => "title",
        :item_published => "published",
        :item_updated => "updated",
        :item_categories => "category",
        :item_author => "author/name",
        :item_description => "summary",
        :item_content => "content",
      }
    end
  end
end
