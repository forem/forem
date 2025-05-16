require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id_no_time) { "fhH5xX_yW6U" }
    let(:valid_id_with_time) { "fhH5xX_yW6U?t=0h5m0s" }
    let(:valid_id_with_time_num) { "fhH5xX_yW6U?t=300" }
    let(:valid_id_with_time_sec) { "fhH5xX_yW6U?t=300s" }    
    let(:valid_url_no_time) { "https://www.youtube.com/watch?v=fhH5xX_yW6U" }
    let(:valid_short_url_no_time) { "https://youtu.be/fhH5xX_yW6U" }
    let(:valid_url_with_time_param) { "https://www.youtube.com/watch?v=fhH5xX_yW6U&t=300s" }
    let(:valid_url_with_time_hash) { "https://www.youtube.com/watch?v=fhH5xX_yW6U#t=300s" }
    let(:valid_embed_url) { "https://www.youtube.com/embed/fhH5xX_yW6U" }
    let(:invalid_id) { Faker::Lorem.characters(number: rand(12..100)) }
    let(:invalid_url) { "https://example.com/video/fhH5xX_yW6U" }

    def generate_new_liquid(input)
      Liquid::Template.register_tag("youtube", YoutubeTag)
      Liquid::Template.parse("{% youtube #{input} %}")
    end

    # rubocop:disable Style/StringLiterals
    describe "with ID input" do
      it "accepts a valid YouTube ID with no starting time" do
        liquid = generate_new_liquid(valid_id_no_time).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end

      it "accepts valid YouTube ID with starting times" do
        liquid = generate_new_liquid(valid_id_with_time).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U?start=300"')
      end

      it "accepts valid YouTube ID with starting time as integer" do
        liquid = generate_new_liquid(valid_id_with_time_num).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U?start=300"')
      end

      it "accepts valid YouTube ID with starting time in seconds" do
        liquid = generate_new_liquid(valid_id_with_time_sec).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U?start=300"')
      end

      it "accepts YouTube ID with no start time and an empty space" do
        liquid = generate_new_liquid("#{valid_id_no_time} ").render
        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end
    end

    describe "with URL input" do
      it "accepts standard YouTube URL with no time" do
        liquid = generate_new_liquid(valid_url_no_time).render
        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end

      it "accepts short YouTube URL with no time" do
        liquid = generate_new_liquid(valid_short_url_no_time).render
        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end
      it "accepts YouTube URL with time parameter" do
        liquid = generate_new_liquid(valid_url_with_time_param).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U?start=300"')
      end

      it "accepts YouTube URL with time hash" do
        liquid = generate_new_liquid(valid_url_with_time_hash).render

        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U?start=300"')
      end

      it "accepts embed YouTube URL" do
        liquid = generate_new_liquid(valid_embed_url).render
        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end
      it "accepts URL with extra whitespace" do
        liquid = generate_new_liquid("#{valid_url_no_time} ").render
        
        expect(liquid).to include('<iframe')
        expect(liquid).to include('src="https://www.youtube.com/embed/fhH5xX_yW6U"')
      end
    end
    # rubocop:enable Style/StringLiterals

    describe "error cases" do
      it "raises an error for invalid IDs" do
        expect { generate_new_liquid(invalid_id).render }.to raise_error("Invalid YouTube ID or URL")
      end
      it "raises an error for invalid URLs" do
        expect { generate_new_liquid(invalid_url).render }.to raise_error("Invalid YouTube ID or URL")
      end
    end
  end
end
