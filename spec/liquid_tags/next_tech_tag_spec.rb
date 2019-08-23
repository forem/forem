require "rails_helper"

RSpec.describe NextTechTag, type: :liquid_template do
  describe "#link" do
    let(:nexttech_link) { "https://www.next.tech/projects/6ba1fffbd09e/share" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("nexttech", NextTechTag)
      Liquid::Template.parse("{% nexttech #{link} %}")
    end

    it "accepts nexttech link" do
      liquid = generate_new_liquid(nexttech_link)
      rendered_nexttech_iframe = liquid.render
      Approvals.verify(rendered_nexttech_iframe, name: "nexttech_liquid_tag", format: :html)
    end

    it "accepts nexttech link with a / at the end" do
      expect do
        generate_new_liquid(nexttech_link + "/")
      end.not_to raise_error
    end

    it "rejects invalid nexttech link" do
      expect do
        generate_new_liquid("https://www.next.tech/projects/1234567890z*/share")
      end.to raise_error(StandardError)
    end
  end
end
