require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id_no_time) { "dQw4w9WgXcQ" }

    let(:valid_ids_with_time) do
      %w[
        QASbw8_0meM?t=8h12m26s
        QASbw8_0meM?t=6h34m
        QASbw8_0meM?t=7h
        QASbw8_0meM?t=1h57s
        dQw4w9WgXcQ?t=4m45s
        dQw4w9WgXcQ?t=5m
        dQw4w9WgXcQ?t=8s
      ]
    end

    let(:invalid_id) { Faker::Lorem.characters(rand(12..100)) }

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

    it "accepts a valid YouTube ID with no starting time" do
      liquid = generate_new_liquid(valid_id_no_time).render
      Approvals.verify(liquid, name: "youtube_liquid_tag_no_time", format: :html)
    end

    it "accepts valid YouTube IDs with starting times" do
      count = 0
      valid_ids_with_time.each do |id|
        liquid = generate_new_liquid(id).render
        count = count + 1
        Approvals.verify(liquid, name: "youtube_liquid_tag_with_time_#{count}", format: :html)
      end
    end

    it "accepts YouTube ID with no start time and an empty space" do
      liquid = generate_new_liquid(valid_id_no_time + " ").render
      Approvals.verify(liquid, name: "youtube_liquid_tag_no_time_trailing_space", format: :html)
    end

    it "accepts YouTube IDs with start times and one empty space" do
      count = 0
      valid_ids_with_time.each do |id|
        liquid = generate_new_liquid(id + " ").render
        count = count + 1
        Approvals.verify(liquid, name: "youtube_liquid_tag_with_time_#{count}", format: :html)
      end
    end

    it "raises an error for invalid IDs" do
      expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid YouTube ID")
    end
  end
end
