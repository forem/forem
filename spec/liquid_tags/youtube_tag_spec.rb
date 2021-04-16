require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id_no_time) { "dQw4w9WgXcQ" }
    let(:valid_ids_with_time) { "QASbw8_0meM?t=8h12m26s" }
    let(:invalid_id) { Faker::Lorem.characters(number: rand(12..100)) }

    def parsed_id(id)
      return id unless id.include?("?t=")

      id_array = id.split("?t=")
      time_hash = {
        h: id_array[1].scan(/\d+h/)[0]&.delete("h").to_i,
        m: id_array[1].scan(/\d+m/)[0]&.delete("m").to_i,
        s: id_array[1].scan(/\d+s/)[0]&.delete("s").to_i
      }
      time_string = ((time_hash[:h] * 3600) + (time_hash[:m] * 60) + time_hash[:s]).to_s
      "#{id_array[0]}?start=#{time_string}"
    end

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
      liquid = generate_new_liquid(valid_ids_with_time).render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/QASbw8_0meM?start=29546"')
    end

    it "accepts YouTube ID with no start time and an empty space" do
      liquid = generate_new_liquid("#{valid_id_no_time} ").render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/dQw4w9WgXcQ"')
    end

    it "accepts YouTube ID with start times and one empty space" do
      liquid = generate_new_liquid("#{valid_ids_with_time} ").render

      expect(liquid).to include('<iframe')
      expect(liquid).to include('src="https://www.youtube.com/embed/QASbw8_0meM?start=29546"')
    end
    # rubocop:enable Style/StringLiterals

    it "raises an error for invalid IDs" do
      expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid YouTube ID")
    end
  end
end
