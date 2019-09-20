require "rails_helper"

vcr_option = {
  cassette_name: "stackexchange_api",
  allow_playback_repeats: "true"
}

RSpec.describe StackexchangeTag, type: :liquid_template, vcr: vcr_option do
  describe "#id" do
    let(:valid_id) { "57496168" }
    let(:exchange_id) { "1163633" }
    let(:invalid_id) { "57496168sddssd" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("stackoverflow", StackexchangeTag)
      Liquid::Template.parse("{% stackoverflow #{id} %}")
    end

    def generate_exchange_liquid(id)
      Liquid::Template.register_tag("stackexchange", StackexchangeTag)
      Liquid::Template.parse("{% stackexchange #{id} askubuntu %}")
    end

    it "renders basic html" do
      liquid = generate_new_liquid(valid_id)
      expect(liquid.render).to include("ltag__stackexchange")
    end

    it "renders basic exchange html" do
      liquid = generate_exchange_liquid(exchange_id)
      expect(liquid.render).to include("stackexchange-logo")
    end

    it "rejects invalid id" do
      expect do
        liquid = generate_exchange_liquid(invalid_id)
        liquid.render
      end.to raise_error(StandardError)
    end
  end
end
