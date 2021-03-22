require "rails_helper"

RSpec.describe NextTechTag, type: :liquid_template do
  describe "#link" do
    let(:nexttech_link) { "https://nt.dev/s/6ba1fffbd09e" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("nexttech", NextTechTag)
      Liquid::Template.parse("{% nexttech #{link} %}")
    end

    it "accepts nexttech link" do
      liquid = generate_new_liquid(nexttech_link)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include('src="https://next.tech/projects/6ba1fffbd09e/embed"')
        .and include(
          'style="width:100%; height:calc(350px + 8vw); border:0; border-radius: 4px; overflow:hidden;"',
        )
      # rubocop:enable Style/StringLiterals
    end

    it "accepts nexttech link with a / at the end" do
      expect do
        generate_new_liquid("#{nexttech_link}/")
      end.not_to raise_error
    end

    it "rejects invalid nexttech link" do
      expect do
        generate_new_liquid("https://nt.dev/s/1234567890z*")
      end.to raise_error(StandardError)
    end
  end
end
