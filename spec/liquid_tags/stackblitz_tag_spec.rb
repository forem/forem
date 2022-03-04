require "rails_helper"

RSpec.describe StackblitzTag, type: :liquid_tag do
  describe "#id" do
    let(:stackblitz_id) { "ball-demo" }
    let(:stackblitz_id_with_view) { "ball-demo view=preview" }
    let(:stackblitz_id_with_file) { "ball-demo file=style.css" }
    let(:stackblitz_id_with_view_and_file) { "ball-demo view=preview file=style.css" }

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

    it "accepts stackblitz id with a view parameter" do
      expect do
        generate_new_liquid(stackblitz_id_with_view)
      end.not_to raise_error
    end

    it "accepts stackblitz id with a file parameter" do
      expect do
        generate_new_liquid(stackblitz_id_with_file)
      end.not_to raise_error
    end

    it "accepts stackblitz id with a view and file parameter" do
      expect do
        generate_new_liquid(stackblitz_id_with_view_and_file)
      end.not_to raise_error
    end

    it "parses stackblitz id with a view and file parameter" do
      liquid = generate_new_liquid(stackblitz_id_with_view_and_file)
      expect(liquid.render).to include("https://stackblitz.com/edit/ball-demo?view=preview&amp;file=style.css")
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
