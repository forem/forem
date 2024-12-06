require 'spec_helper'

describe MetaInspector::Document do
  describe 'passing the contents of the document as html' do
    let(:doc) { MetaInspector::Document.new('http://cnn.com/', :document => "<html><head><title>Hello From Passed Html</title><a href='/hello'>Hello link</a></head><body></body></html>") }

    it "should get correct links when the url html is passed as an option" do
      expect(doc.links.internal).to eq(["http://cnn.com/hello"])
    end

    it "should get the title" do
      expect(doc.title).to eq("Hello From Passed Html")
    end
  end

  it "should return a String as to_s" do
    expect(MetaInspector::Document.new('http://pagerankalert.com').to_s.class).to eq(String)
  end

  it "should return a Hash with all the values set" do
    doc = MetaInspector::Document.new('http://pagerankalert.com')
    expect(doc.to_hash).to eq({
                            "url"             => "http://pagerankalert.com/",
                            "scheme"          => "http",
                            "host"            => "pagerankalert.com",
                            "root_url"        => "http://pagerankalert.com/",
                            "title"           => "PageRankAlert.com :: Track your PageRank changes & receive alerts",
                            "best_title"      => "PageRankAlert.com :: Track your PageRank changes & receive alerts",
                            "author"          => nil,
                            "best_author"     => nil,
                            "description"     => "Track your PageRank(TM) changes and receive alerts by email",
                            "best_description"=> "Track your PageRank(TM) changes and receive alerts by email",
                            "favicon"         => "http://pagerankalert.com/src/favicon.ico",
                            "links"           => {
                                                    'internal' => ["http://pagerankalert.com/",
                                                                   "http://pagerankalert.com/es?language=es",
                                                                   "http://pagerankalert.com/users/sign_up",
                                                                   "http://pagerankalert.com/users/sign_in"],
                                                    'external' => ["http://pagerankalert.posterous.com/",
                                                                   "http://twitter.com/pagerankalert",
                                                                   "http://twitter.com/share"],
                                                    'non_http' => ["mailto:pagerankalert@gmail.com"]
                                                  },
                            "images"          => ["http://pagerankalert.com/images/pagerank_alert.png?1305794559"],
                            "charset"         => "utf-8",
                            "feeds"           => [{href: "http://feeds.feedburner.com/PageRankAlert", title: "PageRankAlert.com blog", type: "application/rss+xml"}],
                            "h1"              => [],
                            "h2"              => ["Track your PageRank changes"],
                            "h3"              => ["WHAT'S YOUR PAGERANK?"],
                            "h4"              => ["Build your own lists", "Get e-mail alerts", "Track your history"],
                            "h5"              => [],
                            "h6"              => [],
                            "content_type"    => "text/html",
                            "meta_tags"       => {
                                                   "name" => {
                                                               "description" => ["Track your PageRank(TM) changes and receive alerts by email"],
                                                               "keywords"    => ["pagerank, seo, optimization, google"], "robots"=>["all,follow"],
                                                               "csrf-param"  => ["authenticity_token"],
                                                               "csrf-token"  => ["iW1/w+R8zrtDkhOlivkLZ793BN04Kr3X/pS+ixObHsE="]
                                                             },
                                                   "http-equiv" => {},
                                                   "property"   => {},
                                                   "charset"    => ["utf-8"]
                                                 },
                            "response"        => {
                                                   "status"  => 200,
                                                   "headers" => {
                                                                  "server" => "nginx/0.7.67",
                                                                  "date"=>"Mon, 30 May 2011 09:45:42 GMT",
                                                                  "content-type" => "text/html; charset=utf-8",
                                                                  "connection" => "keep-alive",
                                                                  "etag" => "\"d0534cf7ad7d7a7fb737fe4ad99b0fd1\"",
                                                                  "x-ua-compatible" => "IE=Edge,chrome=1",
                                                                  "x-runtime" => "0.031274",
                                                                  "set-cookie" => "_session_id=33575f7694b4492af4c4e282d62a7127; path=/; HttpOnly",
                                                                  "cache-control" => "max-age=0, private, must-revalidate",
                                                                  "content-length" => "6690",
                                                                  "x-varnish" => "2167295052",
                                                                  "age" => "0",
                                                                  "via" => "1.1 varnish"
                                                                }
                                                 }
                         })
  end

  describe "allow_non_html_content option" do
    it "should not allow non-html content type by default" do
      expect do
        image_url = MetaInspector::Document.new('http://pagerankalert.com/image.png')
        image_url.title
      end.to raise_error(MetaInspector::NonHtmlError)
    end

    it "should not allow non-html content type when explicitly disallowed" do
      expect do
        image_url = MetaInspector::Document.new('http://pagerankalert.com/image.png', allow_non_html_content: false)
        image_url.title
      end.to raise_error(MetaInspector::NonHtmlError)
    end

    it "should allow non-html content type when explicitly allowed" do
      expect do
        image_url = MetaInspector::Document.new('http://pagerankalert.com/image.png', allow_non_html_content: true)
        image_url.title
      end.to_not raise_error
    end
  end

  describe 'headers' do
    it "should include default headers" do
      url = "http://pagerankalert.com/"
      expected_headers = {'User-Agent' => "MetaInspector/#{MetaInspector::VERSION} (+https://github.com/jaimeiniesta/metainspector)", 'Accept-Encoding' => 'identity'}

      headers = {}
      expect(headers).to receive(:merge!).with(expected_headers)
      allow_any_instance_of(Faraday::Connection).to receive(:headers){headers}
      MetaInspector::Document.new(url)
    end

    it "should include passed headers on the request" do
      url = "http://pagerankalert.com/"
      headers = {'User-Agent' => 'Mozilla', 'Referer' => 'https://github.com/'}

      headers = {}
      expect(headers).to receive(:merge!).with(headers)
      allow_any_instance_of(Faraday::Connection).to receive(:headers){headers}
      MetaInspector::Document.new(url, headers: headers)
    end
  end

  describe 'url normalization' do
    it 'should normalize by default' do
      expect(MetaInspector.new('http://example.com?name=joe martins', allow_redirections: false).url).to eq('http://example.com/?name=joe%20martins')
    end

    it 'should not normalize if the normalize_url option is false' do
      expect(MetaInspector.new('http://example.com?name=joe martins', normalize_url: false, allow_redirections: false).url).to eq('http://example.com?name=joe martins')
    end
  end

  describe 'page encoding' do
    it 'should encode title according to the charset' do
      expect(MetaInspector.new('http://example-rtl.com/').title).to eq('بالفيديو.. "مصطفى بكري" : انتخابات الائتلاف غير نزيهة وموجهة لفوز أشخاص بعينها')
    end

    it 'should encode description according to the charset' do
      expect(MetaInspector.new('http://example-rtl.com/').description).to eq('أعلن النائب مصطفى بكري انسحابه من ائتلاف  دعم مصر  بعد اعتراضه على نتيجة الانتخابات الداخلية للائتلاف، وخسارته فيها، وقال إنه سيترشح غدا على منصب الوكيل بالمجلس')
    end

    it 'should replace NULL characters' do
      doc = MetaInspector.new('http://example-rtl.com/').parsed

      image_src = doc.css('.some_class').first.attribute('src').value

      expect(image_src).to eq('/path/to/image.jpg')
    end

    it "can have a forced encoding" do
      page = MetaInspector.new('http://example.com/invalid_utf8_byte_seq', encoding: "UTF-8")

      expect(page.title).to eq("¡¡Quiero Reciclar!! // ¿Dónde reciclar?, Plataforma Urbana")
    end
  end
end
