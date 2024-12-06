require 'spec_helper'

describe MetaInspector do
  describe "#images" do
    describe "returns an Enumerable" do
      let(:page) { MetaInspector.new('https://twitter.com/markupvalidator') }

      it "responds to #length" do
        expect(page.images.length).to eq(6)
      end

      it "responds to #size" do
        expect(page.images.size).to eq(6)
      end

      it "responds to #each" do
        c = []
        page.images.each {|i| c << i}
        expect(c.length).to eq(6)
      end

      it "responds to #sort" do
        expect(page.images.sort)
          .to eq(["https://si0.twimg.com/sticky/default_profile_images/default_profile_6_mini.png",
                      "https://twimg0-a.akamaihd.net/a/1342841381/images/bigger_spinner.gif",
                      "https://twimg0-a.akamaihd.net/profile_images/1538528659/jaime_nov_08_normal.jpg",
                      "https://twimg0-a.akamaihd.net/profile_images/2293774732/v0pgo4xpdd9rou2xq5h0_normal.png",
                      "https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_normal.png",
                      "https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_reasonably_small.png"])
      end

      it "responds to #first" do
        expect(page.images.first).to eq("https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_reasonably_small.png")
      end

      it "responds to #last" do
        expect(page.images.last).to eq("https://twimg0-a.akamaihd.net/a/1342841381/images/bigger_spinner.gif")
      end

      it "responds to #[]" do
        expect(page.images[0]).to eq("https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_reasonably_small.png")
      end

    end

    it "should find all page images" do
      page = MetaInspector.new('http://pagerankalert.com')

      expect(page.images.to_a).to eq(["http://pagerankalert.com/images/pagerank_alert.png?1305794559"])
    end

    it "should find images on twitter" do
      page = MetaInspector.new('https://twitter.com/markupvalidator')

      expect(page.images.length).to eq(6)
      expect(page.images.to_a).to eq(["https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_reasonably_small.png",
                             "https://twimg0-a.akamaihd.net/profile_images/2380086215/fcu46ozay5f5al9kdfvq_normal.png",
                             "https://twimg0-a.akamaihd.net/profile_images/2293774732/v0pgo4xpdd9rou2xq5h0_normal.png",
                             "https://twimg0-a.akamaihd.net/profile_images/1538528659/jaime_nov_08_normal.jpg",
                             "https://si0.twimg.com/sticky/default_profile_images/default_profile_6_mini.png",
                             "https://twimg0-a.akamaihd.net/a/1342841381/images/bigger_spinner.gif"])
    end

    it "should ignore malformed image tags" do
      # There is an image tag without a source. The scraper should not fatal.
      page = MetaInspector.new("http://www.guardian.co.uk/media/pda/2011/sep/15/techcrunch-arrington-startups")

      expect(page.images.size).to eq(11)
    end
  end

  describe "images.best" do
    it "should find the og image" do
      page = MetaInspector.new('http://www.theonion.com/articles/apple-claims-new-iphone-only-visible-to-most-loyal,2772/')

      expect(page.images.best).to eq("http://o.onionstatic.com/images/articles/article/2772/Apple-Claims-600w-R_jpg_130x110_q85.jpg")
    end

    it "should find image on youtube" do
      page = MetaInspector.new('http://www.youtube.com/watch?v=iaGSSrp49uc')

      expect(page.images.best).to eq("http://i2.ytimg.com/vi/iaGSSrp49uc/mqdefault.jpg")
    end

    it "should find image when og:image and twitter:image metatags are missing" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size')

      expect(page.images.best).to eq("http://example.com/100x100")
    end

    it "should find image when og:image and twitter:image metatags are present but empty" do
      page = MetaInspector.new('http://example.com/meta_tags_empty')

      expect(page.images.best).to eq("http://example.com/100x100")
    end

    it "should find image when some img tag has no src attribute" do
      page = MetaInspector.new('http://example.com/malformed_image_in_html')

      expect(page.images.best).to eq("http://example.com/largest")
    end

  end

  describe "images.owner_suggested" do
    it "should find the og image" do
      page = MetaInspector.new('http://www.theonion.com/articles/apple-claims-new-iphone-only-visible-to-most-loyal,2772/')

      expect(page.images.owner_suggested).to eq("http://o.onionstatic.com/images/articles/article/2772/Apple-Claims-600w-R_jpg_130x110_q85.jpg")
    end

    it "should find image on youtube" do
      page = MetaInspector.new('http://www.youtube.com/watch?v=iaGSSrp49uc')

      expect(page.images.owner_suggested).to eq("http://i2.ytimg.com/vi/iaGSSrp49uc/mqdefault.jpg")
    end

    it "should absolutify image" do
      page = MetaInspector.new('http://www.24-horas.mx/mexico-firma-acuerdo-bilateral-automotriz-con-argentina/')

      expect(page.images.owner_suggested).to eq("http://www.24-horas.mx/wp-content/uploads/2015/03/50316106.jpg")
    end

    it "should return nil when og:image and twitter:image metatags are missing" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size')

      expect(page.images.owner_suggested).to be nil
    end

    it "should not normalize image" do
      page = MetaInspector.new("http://www.guardian.co.uk/media/pda/2011/sep/15/techcrunch-arrington-startups")

      expect(page.images.owner_suggested).to eq("https://i.guim.co.uk/img/media/020bf03ae1d259626803b6c83ac57fd57382f285/0_102_5760_3456/master/5760.jpg?width=1200&height=630&quality=85&auto=format&fit=crop&overlay-align=bottom%2Cleft&overlay-width=100p&overlay-base64=L2ltZy9zdGF0aWMvb3ZlcmxheXMvdGctZGVmYXVsdC5wbmc&s=46e054247285bdf48a7621d371fc5070")
    end
  end

  describe "images.with_size" do
    it "should return sorted by area array of [img_url, width, height] using html sizes" do
      page = MetaInspector.new('http://example.com/largest_image_in_html')

      expect(page.images.with_size).to eq([
        ["http://example.com/largest", 100, 100],
        ["http://example.com/too_narrow", 10, 100],
        ["http://example.com/too_wide", 100, 10],
        ["http://example.com/smaller", 10, 10],
        ["http://example.com/smallest", 1, 1]
      ])
    end

    it "should return sorted by area array of [img_url, width, height] using actual image sizes" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size')

      expect(page.images.with_size).to eq([
        ["http://example.com/100x100", 100, 100],
        ["http://example.com/10x100", 10, 100],
        ["http://example.com/100x10", 100, 10],
        ["http://example.com/10x10", 10, 10],
        ["http://example.com/1x1", 1, 1]
      ])
    end

    it "should return sorted by area array of [img_url, width, height] without downloading images" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size', download_images: false)

      expect(page.images.with_size).to eq([
        ["http://example.com/10x100", 10, 100],
        ["http://example.com/100x10", 100, 10],
        ["http://example.com/1x1", 1, 1],
        ["http://example.com/10x10", 0, 0],
        ["http://example.com/100x100", 0, 0]
      ])
    end
  end

  describe "images.largest" do
    it "should find the largest image on the page using html sizes" do
      page = MetaInspector.new('http://example.com/largest_image_in_html')

      expect(page.images.largest).to eq("http://example.com/largest")
    end

    it "should find the largest image on the page using actual image sizes" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size')

      expect(page.images.largest).to eq("http://example.com/100x100")
    end

    it "should find the largest image without downloading images" do
      page = MetaInspector.new('http://example.com/largest_image_using_image_size', download_images: false)

      expect(page.images.largest).to eq("http://example.com/1x1")
    end
  end

  describe '#favicon' do
    it "should get favicon link when marked as icon" do
      page = MetaInspector.new('http://pagerankalert.com/')

      expect(page.images.favicon).to eq('http://pagerankalert.com/src/favicon.ico')
    end

    it "should get favicon link when marked as shortcut" do
      page = MetaInspector.new('http://pagerankalert-shortcut.com/')

      expect(page.images.favicon).to eq('http://pagerankalert-shortcut.com/src/favicon.ico')
    end

    it "should get favicon link when marked as shorcut and icon" do
      page = MetaInspector.new('http://pagerankalert-shortcut-and-icon.com/')

      expect(page.images.favicon).to eq('http://pagerankalert-shortcut-and-icon.com/src/favicon.ico')
    end

    it "should get favicon link when there is also a touch icon" do
      page = MetaInspector.new('http://pagerankalert-touch-icon.com/')

      expect(page.images.favicon).to eq('http://pagerankalert-touch-icon.com/src/favicon.ico')
    end

    it "should get favicon link of nil" do
      page = MetaInspector.new('http://www.theonion.com/articles/apple-claims-new-iphone-only-visible-to-most-loyal,2772/')

      expect(page.images.favicon).to eq(nil)
    end
  end

  describe 'protocol-relative' do
    before(:each) do
      @m_http   = MetaInspector.new('http://protocol-relative.com')
      @m_https  = MetaInspector.new('https://protocol-relative.com')
    end

    it 'should unrelativize images' do
      expect(@m_http.images.to_a).to eq(['http://example.com/image.jpg'])
      expect(@m_https.images.to_a).to eq(['https://example.com/image.jpg'])
    end

    it 'should unrelativize owner suggested image' do
      expect(@m_http.images.owner_suggested).to eq('http://static-secure.guim.co.uk/sys-images/Guardian/Pix/pictures/2011/8/8/1312810126887/gu_192x115.jpg')
      expect(@m_https.images.owner_suggested).to eq('https://static-secure.guim.co.uk/sys-images/Guardian/Pix/pictures/2011/8/8/1312810126887/gu_192x115.jpg')
    end

    it 'should unrelativize favicon' do
      expect(@m_http.images.favicon).to eq('http://static-secure.guim.co.uk/sys-images/favicon.ico')
      expect(@m_https.images.favicon).to eq('https://static-secure.guim.co.uk/sys-images/favicon.ico')
    end
  end
end
