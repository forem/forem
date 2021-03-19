require "rails_helper"

RSpec.describe ParlerTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id) do
      "https://www.parler.io/audio/73240183203/d53cff009eac2ab1bc9dd8821a638823c39cbcea.7dd28611-b7fc-4cf8-9977-b6e3aaf644a1.mp3"
    end

    let(:invalid_id) { "https://www.google.com" }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("parler", ParlerTag)
      Liquid::Template.parse("{% parler #{id} %}")
    end

    it "accepts a valid Parler URL" do
      liquid = generate_new_liquid(valid_id)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include("https://api.parler.io/ss/player?url=#{valid_id}")
      # rubocop:enable Style/StringLiterals
    end

    it "raises an error for invalid IDs" do
      expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid Parler URL")
    end
  end
end
