require "rails_helper"

RSpec.describe StackblitzTag, type: :liquid_tag do
  describe "#id" do
    let(:stackblitz_id) { "ball-demo" }

    xss_links = %w(
      //evil.com/?ball-demo
      https://ball-demo.evil.com
      ball-demo" onload='alert("xss")'
    )

    def generate_new_liquid(id)
      Liquid::Template.register_tag("stackblitz", StackblitzTag)
      Liquid::Template.parse("{% stackblitz #{id} %}")
    end

    it "renders iframe" do
      liquid = generate_new_liquid(stackblitz_id)
      expect(liquid.render).to include("<iframe")
    end

    it "rejects invalid stackblitz id" do
      expect do
        generate_new_liquid("https://google.com")
      end.to raise_error(StandardError)
    end

    it "parses stackblitz id with a view parameter" do
      liquid = generate_new_liquid("ball-demo view=preview")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?view=preview")
    end

    it "parses stackblitz id with a file parameter" do
      liquid = generate_new_liquid("ball-demo file=style.css")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?file=style.css")
    end

    it "parses stackblitz id with a view and file parameter" do
      liquid = generate_new_liquid("ball-demo view=preview file=style.css")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?view=preview&amp;file=style.css")
    end

    it "parses stackblitz id with an embed parameter" do
      liquid = generate_new_liquid("ball-demo embed=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?embed=1")
    end

    it "parses stackblitz id with a hideNavigation parameter" do
      liquid = generate_new_liquid("ball-demo hideNavigation=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?hideNavigation=1")
    end

    it "parses stackblitz id with a theme parameter" do
      liquid = generate_new_liquid("ball-demo theme=dark")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?theme=dark")
    end

    it "parses stackblitz id with a ctl parameter" do
      liquid = generate_new_liquid("ball-demo ctl=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?ctl=1")
    end

    it "parses stackblitz id with a devtoolsheight parameter" do
      liquid = generate_new_liquid("ball-demo devtoolsheight=80")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?devtoolsheight=80")
    end

    it "parses stackblitz id with a hidedevtools parameter" do
      liquid = generate_new_liquid("ball-demo hidedevtools=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?hidedevtools=1")
    end

    it "parses stackblitz id with a initialpath parameter" do
      liquid = generate_new_liquid("ball-demo initialpath=/foo/index.html")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?initialpath=/foo/index.html")
    end

    it "parses stackblitz id with a showSidebar parameter" do
      liquid = generate_new_liquid("ball-demo showSidebar=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?showSidebar=1")
    end

    it "parses stackblitz id with a terminalHeight parameter" do
      liquid = generate_new_liquid("ball-demo terminalHeight=80")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?terminalHeight=80")
    end

    it "parses stackblitz id with a startScript parameter" do
      liquid = generate_new_liquid("ball-demo startScript=dev")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?startScript=dev")
    end

    it "removes invalid parameters" do
      liquid = generate_new_liquid("ball-demo foo=bar bar=baz showSidebar=1")
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?showSidebar=1")
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
