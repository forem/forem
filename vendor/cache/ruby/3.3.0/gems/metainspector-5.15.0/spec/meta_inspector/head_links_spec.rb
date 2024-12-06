require 'spec_helper'

describe MetaInspector do
  describe "head_links" do
    let(:page) { MetaInspector.new('http://example.com/head_links') }
    let(:page_https) { MetaInspector.new('https://example.com/head_links') }

    it "#head_links" do
      expect(page.head_links).to eq([
                                        {rel: 'canonical', href: 'http://example.com/canonical-from-head'},
                                        {rel: 'stylesheet', href: 'http://example.com/stylesheets/screen.css'},
                                        {rel: 'stylesheet', href: 'http://example2.com/stylesheets/screen.css'},
                                        {rel: 'shortcut icon', href: 'http://example.com/favicon.ico', type: 'image/x-icon'},
                                        {rel: 'shorturl', href: 'http://gu.com/p/32v5a'},
                                        {rel: 'stylesheet', type: 'text/css', href: 'http://foo/print.css', media: 'print', class: 'contrast'}
                                    ])
    end

    it "#stylesheets" do
      expect(page.stylesheets).to eq([
                                         {rel: 'stylesheet', href: 'http://example.com/stylesheets/screen.css'},
                                         {rel: 'stylesheet', href: 'http://example2.com/stylesheets/screen.css'},
                                         {rel: 'stylesheet', type: 'text/css', href: 'http://foo/print.css', media: 'print', class: 'contrast'}
                                     ])

      expect(page_https.stylesheets).to eq([
                                         {rel: 'stylesheet', href: 'https://example.com/stylesheets/screen.css'},
                                         {rel: 'stylesheet', href: 'https://example2.com/stylesheets/screen.css'},
                                         {rel: 'stylesheet', type: 'text/css', href: 'http://foo/print.css', media: 'print', class: 'contrast'}
                                     ])
    end

    it "#canonical" do
      expect(page.canonicals).to eq([
                                        {rel: 'canonical', href: 'http://example.com/canonical-from-head'}
                                    ])
    end

    context "on page with some broken feed links" do
      let(:page){ MetaInspector.new('http://example.com/broken_head_links') }
      it "tries to find correct one" do
        expected = [
          { title: "TechCrunch RSS feed", href: "http://www.guardian.co.uk/media/techcrunch/rss", type: "application/rss+xml" }
        ]
        expect(page.feeds).to eq(expected)
      end
    end
  end

end
