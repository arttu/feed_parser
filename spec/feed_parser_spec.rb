require 'feed_parser'

class NotSaneSanitizer
  def sanitize(str)
    str.gsub(/flowdock/i, '').gsub('Karri Saarinen', 'Sanitized')
  end
end

describe FeedParser do
  describe FeedParser::Feed, "#new" do
    def feed_xml
      File.read(File.join(File.dirname(__FILE__), 'fixtures', 'nodeta.rss.xml'))
    end

    it "should fetch a feed by url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/").and_return(feed_xml)
      FeedParser::Feed.new("http://blog.example.com/feed/")
    end

    it "should fetch a feed using basic auth if auth embedded to the url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", :http_basic_authentication => ["user", "pass"]).and_return(feed_xml)
      FeedParser::Feed.new("http://user:pass@blog.example.com/feed/")
    end

    it "should fetch a feed with only a user name embedded to the url" do
      FeedParser::Feed.any_instance.should_receive(:open).with("http://blog.example.com/feed/", :http_basic_authentication => ["user"]).and_return(feed_xml)
      FeedParser::Feed.new("http://user@blog.example.com/feed/")
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
