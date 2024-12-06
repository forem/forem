require 'spec_helper'

describe MetaInspector do
  let(:page)   { MetaInspector.new('http://example.com') }

  describe '#links' do
    it 'returns the internal links' do
      expect(page.links.internal).to eq([ "http://example.com/",
                                        "http://example.com/faqs",
                                        "http://example.com/contact",
                                        "http://example.com/team.html" ])
    end

    it 'returns the external links' do
      expect(page.links.external).to eq([ "https://twitter.com/",
                                        "https://github.com/" ])
    end

    it 'returns the non-HTTP links' do
      expect(page.links.non_http).to eq([ "mailto:hello@example.com",
                                        "javascript:alert('hi');",
                                        "ftp://ftp.example.com/" ])
    end
  end

  describe 'Links' do
    before(:each) do
      @m = MetaInspector.new('http://pagerankalert.com')
    end

    it "should get correct absolute links for internal pages" do
      expect(@m.links.internal).to eq([ "http://pagerankalert.com/",
                                      "http://pagerankalert.com/es?language=es",
                                      "http://pagerankalert.com/users/sign_up",
                                      "http://pagerankalert.com/users/sign_in" ])
    end

    it "should get correct absolute links for external pages" do
      expect(@m.links.external).to eq([ "http://pagerankalert.posterous.com/",
                                      "http://twitter.com/pagerankalert",
                                      "http://twitter.com/share" ])
    end

    it "should get correct absolute links, correcting relative links from URL not ending with slash" do
      m = MetaInspector.new('http://alazan.com/websolution.asp')

      expect(m.links.internal).to eq([ "http://alazan.com/index.asp",
                                     "http://alazan.com/faqs.asp" ])
    end

    describe "links with international characters" do
      it "should get correct absolute links, encoding the URLs as needed" do
        m = MetaInspector.new('http://international.com')

        expect(m.links.internal).to eq([ "http://international.com/espa%C3%B1a.asp",
                                       "http://international.com/roman%C3%A9e",
                                       "http://international.com/faqs#cami%C3%B3n",
                                       "http://international.com/search?q=cami%C3%B3n",
                                       "http://international.com/search?q=espa%C3%B1a#top",
                                       "http://international.com/index.php?q=espa%C3%B1a&url=aHR0zZQ==&cntnt01pageid=21"])

        expect(m.links.external).to eq([ "http://example.com/espa%C3%B1a.asp",
                                       "http://example.com/roman%C3%A9e",
                                       "http://example.com/faqs#cami%C3%B3n",
                                       "http://example.com/search?q=cami%C3%B3n",
                                       "http://example.com/search?q=espa%C3%B1a#top"])
      end

      describe "internal links" do
        it "should get correct internal links, encoding the URLs as needed but respecting # and ?" do
          m = MetaInspector.new('http://international.com')
          expect(m.links.internal).to eq([ "http://international.com/espa%C3%B1a.asp",
                                       "http://international.com/roman%C3%A9e",
                                       "http://international.com/faqs#cami%C3%B3n",
                                       "http://international.com/search?q=cami%C3%B3n",
                                       "http://international.com/search?q=espa%C3%B1a#top",
                                       "http://international.com/index.php?q=espa%C3%B1a&url=aHR0zZQ==&cntnt01pageid=21"])
        end

        it "should not crash when processing malformed hrefs" do
          m = MetaInspector.new('http://example.com/malformed_href')
          expect(m.links.internal).to eq([ "http://example.com/faqs" ])
        end
      end

      describe "external links" do
        it "should get correct external links, encoding the URLs as needed but respecting # and ?" do
          m = MetaInspector.new('http://international.com')
          expect(m.links.external).to eq([ "http://example.com/espa%C3%B1a.asp",
                                       "http://example.com/roman%C3%A9e",
                                       "http://example.com/faqs#cami%C3%B3n",
                                       "http://example.com/search?q=cami%C3%B3n",
                                       "http://example.com/search?q=espa%C3%B1a#top"])
        end

        it "should not crash when processing malformed hrefs" do
          m = MetaInspector.new('http://example.com/malformed_href')
          expect(m.links.non_http).to eq(["skype:joeuser?call", "telnet://telnet.cdrom.com", "javascript:alert('ok');",
                                          "tel:08%208267%203255", "javascript://", "mailto:email(at)example.com"])
        end
      end
    end

    it "should not crash with links that have weird href values, filtering them out" do
      m = MetaInspector.new('http://example.com/invalid_href')
      expect(m.links.non_http).to eq(["skype:joeuser?call", "telnet://telnet.cdrom.com"])
    end

    it "should handle links that have an invalid byte sequence" do
      m = MetaInspector.new('http://example.com/invalid_byte_seq')
      expect(m.links.all).to eq(["http://pagerankalert.posterous.com/", "http://twitter.com/pagerankalert"])
    end

  end

  describe 'Relative links' do
    describe 'From a root URL' do
      before(:each) do
        @m = MetaInspector.new('http://relative.com/')
      end

      it 'should get the relative links' do
        expect(@m.links.internal).to eq(['http://relative.com/about', 'http://relative.com/sitemap'])
      end
    end

    describe 'From a document' do
      before(:each) do
        @m = MetaInspector.new('http://relative.com/company')
      end

      it 'should get the relative links' do
        expect(@m.links.internal).to eq(['http://relative.com/about', 'http://relative.com/sitemap'])
      end
    end

    describe 'From a directory' do
      before(:each) do
        @m = MetaInspector.new('http://relative.com/company/')
      end

      it 'should get the relative links' do
        expect(@m.links.internal).to eq(['http://relative.com/company/about', 'http://relative.com/sitemap'])
      end
    end
  end

  describe 'Relative links with empty or blank base' do
    it 'should get the relative links from a document' do
      m = MetaInspector.new('http://relativewithemptybase.com/company')
      expect(m.links.internal).to eq(['http://relativewithemptybase.com/about', 'http://relativewithemptybase.com/sitemap'])
    end
  end

  describe 'Relative links with base' do
    it 'should get the relative links from a document' do
      m = MetaInspector.new('http://relativewithbase.com/company/page2')
      expect(m.links.internal).to eq(['http://relativewithbase.com/about', 'http://relativewithbase.com/sitemap'])
    end

    it 'should get the relative links from a directory' do
      m = MetaInspector.new('http://relativewithbase.com/company/page2/')
      expect(m.links.internal).to eq(['http://relativewithbase.com/about', 'http://relativewithbase.com/sitemap'])
    end
  end

  describe 'Relative links with relative base' do
    it 'should get the relative links with relative directory base' do
      m = MetaInspector.new('http://relativewithrelativebase.com/relativedir')
      expect(m.links.all).to eq(['http://relativewithrelativebase.com/other/about',
                                 'http://relativewithrelativebase.com/sitemap'])
    end

    it 'should get the relative links with relative document base' do
      m = MetaInspector.new('http://relativewithrelativebase.com/relativedoc')
      expect(m.links.all).to eq(['http://relativewithrelativebase.com/about',
                                 'http://relativewithrelativebase.com/sitemap'])
    end

    it 'should get the relative links with relative root base' do
      m = MetaInspector.new('http://relativewithrelativebase.com/')
      expect(m.links.all).to eq(['http://relativewithrelativebase.com/about',
                                 'http://relativewithrelativebase.com/sitemap'])
    end
  end

  describe 'Non-HTTP links' do
    before(:each) do
      @m = MetaInspector.new('http://example.com/nonhttp')
    end

    it "should get the links" do
      expect(@m.links.non_http.sort).to eq([
                                "ftp://ftp.cdrom.com/",
                                "javascript:alert('hey');",
                                "mailto:user@example.com",
                                "skype:joeuser?call",
                                "telnet://telnet.cdrom.com"
                              ])
    end
  end

  describe 'Protocol-relative URLs' do
    before(:each) do
      @m_http   = MetaInspector.new('http://protocol-relative.com')
      @m_https  = MetaInspector.new('https://protocol-relative.com')
    end

    it "should convert protocol-relative links to http" do
      expect(@m_http.links.internal).to include('http://protocol-relative.com/contact')
      expect(@m_http.links.external).to include('http://yahoo.com/')
    end

    it "should convert protocol-relative links to https" do
      expect(@m_https.links.internal).to include('https://protocol-relative.com/contact')
      expect(@m_https.links.external).to include('https://yahoo.com/')
    end
  end

  context "Feeds" do
    let(:meta) { MetaInspector.new('http://feeds.example.com') }

    describe "#feeds" do
      it "should return all the document's feeds" do
        expected = [
          { title: "Articles - JSON Feed", href: "https://example.org/feed.json",          type: "application/json" },
          { title: "Comments - JSON Feed", href: "https://example.org/feed/comments.json", type: "application/json" },
          { title: "Articles - RSS Feed",  href: "https://example.org/feed.rss",           type: "application/rss+xml" },
          { title: "Comments - RSS Feed",  href: "https://example.org/feed/comments.rss",  type: "application/rss+xml" },
          { title: "Articles - Atom Feed", href: "https://example.org/feed.xml",           type: "application/atom+xml" },
          { title: "Comments - Atom Feed", href: "https://example.org/feed/comments.xml",  type: "application/atom+xml" }
        ]
        expect(meta.feeds).to eq(expected)
      end

      it "should return nothing if no feeds found" do
        @m = MetaInspector.new('http://www.alazan.com')
        expect(@m.feeds).to eq([])
      end
    end
  end
end
