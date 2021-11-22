require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id_no_time) { "dQw4w9WgXcQ" }
    let(:valid_id_with_time) { "QASbw8_0meM?t=8h12m26s" }
    let(:invalid_id) { Faker::Lorem.characters(number: rand(12..100)) }

    def generate_new_liquid(id)
      Liquid::Template.register_tag("youtube", YoutubeTag)
      Liquid::Template.parse("{% youtube #{id} %}")
    end

    # rubocop:disable Style/StringLiterals
    it "accepts a valid YouTube ID with no starting time" do
      liquid = generate_new_liquid(valid_id_no_time).render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/dQw4w9WgXcQ"')
    end

    it "accepts valid YouTube ID with starting times" do
      liquid = generate_new_liquid(valid_id_with_time).render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/QASbw8_0meM?start=29546"')
    end

    it "accepts YouTube ID with no start time and an empty space" do
      liquid = generate_new_liquid("#{valid_id_no_time} ").render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/dQw4w9WgXcQ"')
    end

    it "accepts YouTube ID with start times and one empty space" do
      liquid = generate_new_liquid("#{valid_id_with_time} ").render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/QASbw8_0meM?start=29546"')
    end
    # rubocop:enable Style/StringLiterals

    it "raises an error for invalid IDs" do
      expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid YouTube ID")
    end
  end
end
