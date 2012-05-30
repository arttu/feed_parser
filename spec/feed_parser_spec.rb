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
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)).and_return(feed_xml)
      fp = FeedParser.new(:url => "http://blog.example.com/feed/", :http => {:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE})
      fp.parse
    end
  end

  describe FeedParser::Feed, "#new" do
    it "should fetch a feed by url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options).and_return(feed_xml)
      FeedParser::Feed.new("http://blog.example.com/feed/")
    end

    it "should fetch a feed using basic auth if auth embedded to the url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:http_basic_authentication => ["user", "pass"])).and_return(feed_xml)
      FeedParser::Feed.new("http://user:pass@blog.example.com/feed/")
    end

    it "should fetch a feed with only a user name embedded to the url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", http_connection_options.merge(:http_basic_authentication => ["user"])).and_return(feed_xml)
      FeedParser::Feed.new("http://user@blog.example.com/feed/")
    end

    it "should follow redirect based on the exception message" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://example.com/feed", http_connection_options).and_raise(RuntimeError.new("redirection forbidden: http://example.com/feed -> https://example.com/feed"))
      FeedParser::Feed.any_instance.should_receive(:open).with("https://example.com/feed", http_connection_options).and_return(feed_xml)
      FeedParser::Feed.new("http://example.com/feed")
    end

    it "should not follow redirect from secure connection to non-secure one" do
      FeedParser::Feed.any_instance.should_receive(:open).with("https://example.com/feed", http_connection_options).and_raise(RuntimeError.new("redirection forbidden: https://example.com/feed -> http://example.com/feed"))
      FeedParser::Feed.any_instance.should_not_receive(:open).with("http://example.com/feed", http_connection_options)
      lambda {
        FeedParser::Feed.new("https://example.com/feed")
      }.should raise_error(RuntimeError, "redirection forbidden: https://example.com/feed -> http://example.com/feed")
    end

    it "should use alternate url if there is no valid self url in the received feed xml" do
      FeedParser::Feed.any_instance.should_receive(:open).with("https://developers.facebook.com/blog/feed", http_connection_options).and_return(feed_xml('facebook.atom.xml'))
      lambda {
        feed = FeedParser::Feed.new("https://developers.facebook.com/blog/feed")
        feed.url.should == "https://developers.facebook.com/blog/feed"
      }.should_not raise_error
    end

    it "should raise an error unless retrieved XML is not an RSS or an ATOM feed" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://example.com/blog/feed/invalid.xml", http_connection_options).and_return("foo bar")
      lambda {
        FeedParser::Feed.new("http://example.com/blog/feed/invalid.xml")
      }.should raise_error(FeedParser::UnknownFeedType, "Feed is not an RSS feed or an ATOM feed")
    end
  end

  describe "#parse" do
    shared_examples_for "feed parser" do
      it "should not fail" do
        lambda {
          @feed = @feed_parser.parse
        }.should_not raise_error
      end

      it "should populate every item" do
        @feed = @feed_parser.parse
        @feed.items.each do |item|
          [:guid, :link, :title, :categories, :author, :content].each do |attribute|
            item.send(attribute).should_not be_nil
            item.send(attribute).should_not be_empty
          end
        end
      end
    end

    def case_tester(test_cases)
      test_cases.each do |test_case|
        if test_case.last.is_a?(Array)
          test_case.last.each do |_case|
            @feed.as_json[test_case.first].should include(_case)
          end
        else
          @feed.send(test_case.first).should include(test_case.last)
        end
      end
    end

    describe "rss feeds" do
      before :each do
        @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', 'nodeta.rss.xml'))
      end

      after :each do
        @feed.type.should == :rss
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
          @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', rss_fixture))

          @feed = @feed_parser.parse

          case_tester(test_cases)
        end
      end

      it "should sanitize with custom sanitizer" do
        @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', 'sanitize.me.rss.xml'), :sanitizer => NotSaneSanitizer.new)

        @feed = @feed_parser.parse

        @feed.items.first.content.should_not =~ (/flowdock/i)
      end

      it "should sanitize custom fields" do
        @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', 'sanitize.me.rss.xml'), :sanitizer => NotSaneSanitizer.new, :fields_to_sanitize => [:author, :content])

        @feed = @feed_parser.parse

        @feed.items.first.author.should == 'Sanitized'
      end

      it_should_behave_like "feed parser"
    end

    describe "atom feeds" do
      before :each do
        @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', 'smashingmagazine.atom.xml'))
      end

      after :each do
        @feed.type.should == :atom
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
          @feed_parser = FeedParser.new(:url => File.join(File.dirname(__FILE__), 'fixtures', atom_fixture))

          @feed = @feed_parser.parse

          case_tester(test_cases)
        end
      end

      it_should_behave_like "feed parser"
    end
  end
end
