require 'openssl'
require 'feed_parser'

class NotSaneSanitizer
  def sanitize(str)
    str.gsub(/flowdock/i, '').gsub('Karri Saarinen', 'Sanitized')
  end
end

describe FeedParser do
  def feed_xml(filename = 'nodeta.rss.xml')
    File.read(File.join(File.dirname(__FILE__), 'fixtures', filename))
  end

  def http_connection_options
    opts = {"User-Agent" => FeedParser::USER_AGENT}
    opts[:redirect] = true if RUBY_VERSION >= '1.9'
    opts
  end

  describe "#new" do
    it "should forward given http options to the OpenURI" do
      FeedParser.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)).and_return(feed_xml)
      fp = FeedParser.new(:url => "http://blog.example.com/feed/", :http => {:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE})
      fp.parse
    end

    it "should fetch a feed by url" do
      FeedParser.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options).and_return(feed_xml)
      fp = FeedParser.new({:url => "http://blog.example.com/feed/"}.merge(http_connection_options))
      fp.parse
    end

    it "should fetch a feed using basic auth if auth embedded to the url" do
      FeedParser.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:http_basic_authentication => ["user", "pass"])).and_return(feed_xml)
      fp = FeedParser.new({:url => "http://user:pass@blog.example.com/feed/"}.merge(http_connection_options))
      fp.parse
    end

    it "should fetch a feed with only a user name embedded to the url" do
      FeedParser.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:http_basic_authentication => ["user"])).and_return(feed_xml)
      fp = FeedParser.new({:url => "http://user@blog.example.com/feed/"}.merge(http_connection_options))
      fp.parse
    end

    it "should follow redirect based on the exception message (even if OpenURI don't want to do it)" do
      FeedParser.any_instance.should_receive(:open).with("http://example.com/feed", http_connection_options).and_raise(RuntimeError.new("redirection forbidden: http://example.com/feed -> https://example.com/feed"))
      FeedParser.any_instance.should_receive(:open).with("https://example.com/feed", http_connection_options).and_return(feed_xml)
      fp = FeedParser.new({:url => "http://example.com/feed"}.merge(http_connection_options))
      fp.parse
    end

    it "should not follow redirect from a secure connection to a non-secure one" do
      FeedParser.any_instance.should_receive(:open).with("https://example.com/feed", http_connection_options).and_raise(RuntimeError.new("redirection forbidden: https://example.com/feed -> http://example.com/feed"))
      FeedParser.any_instance.should_not_receive(:open).with("http://example.com/feed", http_connection_options)
      lambda {
        fp = FeedParser.new({:url => "https://example.com/feed"}.merge(http_connection_options))
        fp.parse
      }.should raise_error(RuntimeError, "redirection forbidden: https://example.com/feed -> http://example.com/feed")
    end

    it "should raise an error unless retrieved XML is not an RSS or an ATOM feed" do
      FeedParser.any_instance.should_receive(:open).with("http://example.com/blog/feed/invalid.xml", http_connection_options).and_return("foo bar")
      lambda {
        fp = FeedParser.new({:url => "http://example.com/blog/feed/invalid.xml"}.merge(http_connection_options))
        fp.parse
      }.should raise_error(FeedParser::UnknownFeedType, "Feed is not an RSS feed or an ATOM feed")
    end

    it "should not allow feeds without http(s) protocol" do
      lambda {
        fp = FeedParser.new({:url => "feed://example.com/feed"}.merge(http_connection_options))
        fp.parse
      }.should raise_error(FeedParser::InvalidURI, "Only URIs with http or https protocol are supported")
    end
  end

  describe "::Feed" do
    def case_tester(feed, test_cases)
      test_cases.each do |test_case|
        if test_case.last.is_a?(Array)
          test_case.last.each do |_case|
            feed.as_json[test_case.first].should include(_case)
          end
        else
          feed.send(test_case.first).should include(test_case.last)
        end
      end
    end

    describe "sanitizer" do
      it "should sanitize with custom sanitizer" do
        FeedParser.new(:url => "https://example.com/feed", :sanitizer => NotSaneSanitizer.new)

        feed = FeedParser::Feed.new(feed_xml('sanitize.me.rss.xml'))
        feed.items.first.content.should_not =~ (/flowdock/i)
      end

      it "should sanitize custom fields" do
        FeedParser.new(:url => "https://example.com/feed", :sanitizer => NotSaneSanitizer.new, :fields_to_sanitize => [:author, :content])

        feed = FeedParser::Feed.new(feed_xml('sanitize.me.rss.xml'))
        feed.items.first.author.should == 'Sanitized'
      end
    end

    describe "rss feeds" do
      it "should be an rss feed" do
        feed = FeedParser::Feed.new(feed_xml('nodeta.rss.xml'))
        feed.type.should == :rss
      end

      it "should populate every item" do
        feed = FeedParser::Feed.new(feed_xml('nodeta.rss.xml'))
        feed.items.each do |item|
          [:guid, :link, :title, :categories, :author, :content].each do |attribute|
            item.send(attribute).should_not be_nil
            item.send(attribute).should_not be_empty
          end
        end
      end

      it "should set the published date" do
        feed = FeedParser::Feed.new(feed_xml('nodeta.rss.xml'))
        item = feed.items.first
        item.published.should == DateTime.parse("Jul 5, 2009 09:25:32 GMT")
      end

      {
        'nodeta.rss.xml' => {
          :title => "Nodeta",
          :url => "http://blog.nodeta.fi",
          :items => [
              {
                :guid => "http://blog.nodeta.fi/?p=73",
                :link => "http://blog.nodeta.fi/2009/01/16/ruby-187-imported/",
                :title => "Ruby 1.8.7 imported",
                :published => DateTime.parse("Jan 16, 2009 15:29:52 GMT"),
                :categories => ["APIdock", "Ruby"],
                :author => "Otto Hilska",
                :description => "I just finished importing Ruby 1.8.7 to APIdock. It&#8217;s also the new default version, because usually it is better documented. However, there&#8217;re some incompatibilities between 1.8.6 and 1.8.7, so be sure to check the older documentation when something seems to be wrong.\n",
                :content => "<p>I just finished importing Ruby 1.8.7 to APIdock. It&#8217;s also the new default version, because usually it is better documented. However, there&#8217;re some incompatibilities between 1.8.6 and 1.8.7, so be sure to check the older documentation when something seems to be wrong.</p>\n"
              }
            ]
        },
        'basecamp.rss.xml' => {
          :title => "Awesome project",
          :url => "",
          :items => [
              {
                :guid => "basecamp.00000000.Comment.1234567",
                :link => "https://awesome.basecamphq.com/unique_item_link",
                :title => "Comment posted: Re: Howdy how?",
                :published => DateTime.parse("Nov 9, 2011 20:35:18 GMT"),
                :categories => [],
                :author => "Ffuuuuuuu- Le.",
                :description => "<div>trololooo</div><p>Company: awesome | Project: Awesome project</p>",
                :content => ""
              }
            ]
        },
        'scrumalliance.rss.xml' => {
          :title => "ScrumAlliance",
          :url => "http://scrumalliance.org/",
          :items => [
            {
              :guid => "http://scrumalliance.org/articles/424-testing-in-scrum-with-a-waterfall-interaction",
              :link => "http://scrumalliance.org/articles/424-testing-in-scrum-with-a-waterfall-interaction", # trims the link
              :title => "Testing in Scrum with a Waterfall Interaction",
              :published => DateTime.parse("May 23, 2012 11:07:03 GMT"),
              :categories => [],
              :author => "",
              :description => "Sometimes, when testing user stories in Scrum, there's a final Waterfall  interaction to deal with. The scenario I present here is based on this  situation: a Scrum process with an interaction of sequential phases at  the end of the process to (re)test the whole developed functionality.  These sequential phases are mandatory for our organization, which  follows a Waterfall process for the releases of the product. So, for the  moment at least, we have to deal with this  and my experience is that  we aren't alone.",
              :content => ""
            }
          ]
        },
        'TechCrunch.xml' => {
          :title => "TechCrunch",
          :url => "http://techcrunch.com",
          # items: [] # <- fill in if you want to
        },
      }.each do |rss_fixture, test_cases|
        it "should parse #{rss_fixture}" do
          feed = FeedParser::Feed.new(feed_xml(rss_fixture))

          case_tester(feed, test_cases)
        end
      end
    end

    describe "atom feeds" do
      it "should be an atom feed" do
        feed = FeedParser::Feed.new(feed_xml('smashingmagazine.atom.xml'))
        feed.type.should == :atom
      end

      it "should populate every item" do
        feed = FeedParser::Feed.new(feed_xml('smashingmagazine.atom.xml'))
        feed.items.each do |item|
          [:guid, :link, :title, :categories, :author, :content].each do |attribute|
            item.send(attribute).should_not be_nil
            item.send(attribute).should_not be_empty
          end
        end
      end

      it "should set the published date if present" do
        feed = FeedParser::Feed.new(feed_xml('smashingmagazine.atom.xml'))
        item = feed.items.first
        item.published.should == DateTime.parse("Jul 20, 2009 8:43:22 GMT")
      end

      it "should default the published date to the updated date if not present" do
        feed = FeedParser::Feed.new(feed_xml('facebook.atom.xml'))
        item = feed.items.first
        item.published.should == DateTime.parse("Dec 30, 2011 17:00 GMT")
      end

      {
        'gcal.atom.xml' => {
          :title => "dokaus.net",
          :url => "http://www.google.com/calendar/feeds/gqqcve4dv1skp0ppb3tmbcqtko%40group.calendar.google.com/public/basic?max-results=25",
          # items: [] # <- fill in if you want to
        },
        'smashingmagazine.atom.xml' => {
          :title => "Smashing Magazine",
          :url => "http://www.smashingmagazine.com/feed/atom/",
          # items: [] # <- fill in if you want to
        },
        'facebook.atom.xml' => {
          :items => [
              {
                :guid => "urn:uuid:132266233552163",
                :link => "http://developers.facebook.com/blog/post/614/",
                :title => "Breaking Change: JavaScript SDK to oauth:true on December 13th",
                :published => DateTime.parse("Dec 12, 2011 17:00 GMT"),
                :categories=>[],
                :author => "",
                :description => "",
                :content => '<div><p>As part of our continued efforts to migrate all apps to OAuth 2.0, we are opting in all apps using the new JavaScript SDK to OAuth 2.0 tomorrow at 11am Pacific Time. The deadline to support OAuth 2.0 was <a href="https://developers.facebook.com/docs/oauth2-https-migration/">October 1st, 2011</a>.</p>

<p>The new JS SDK with OAuth 2.0 was introduced in July. Tomorrow, on <b>December 13th at 11am</b>, we will automatically default the <code>oauth</code> param to true in <code>FB.init</code>. With this change, please ensure that you are using <code>FB.getAuthResponse</code> to obtain the access token. Read more about the specific changes that you need to make <a href="https://developers.facebook.com/blog/post/525/">here</a>.</p>
</div>'
              }
            ]
        }
      }.each do |atom_fixture, test_cases|
        it "should parse #{atom_fixture}" do
          feed = FeedParser::Feed.new(feed_xml(atom_fixture))

          case_tester(feed, test_cases)
        end
      end

      it "should use alternate url if there is no valid self url in the received feed xml" do
        lambda {
          feed = FeedParser::Feed.new(feed_xml('facebook.atom.xml'))
          feed.url.should == "https://developers.facebook.com/blog/feed"
        }.should_not raise_error
      end
    end
  end
end
