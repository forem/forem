require "rails_helper"

RSpec.describe MediaStore do
  describe "enums" do
    it { is_expected.to define_enum_for(:media_type).with_values(%i[image video audio]) }
  end

  describe "callbacks" do
    context "when before_validation" do
      let(:media_store) { build(:media_store, original_url: "http://example.com/image.jpg", output_url: nil) }

      it "calls set_output_url_if_needed" do
        expect(media_store).to receive(:set_output_url_if_needed) # rubocop:disable RSpec/MessageSpies,RSpec/MessageExpectation
        media_store.valid?
      end

      it "sets output_url if it's nil" do
        uploader = instance_double(ArticleImageUploader)
        allow(ArticleImageUploader).to receive(:new).and_return(uploader)
        allow(uploader).to receive(:upload_from_url).with("http://example.com/image.jpg").and_return("http://example.com/output.jpg")

        media_store.valid?

        expect(media_store.output_url).to eq("http://example.com/output.jpg")
      end

      it "does not change output_url if it is already present" do
        media_store.output_url = "http://example.com/existing_output.jpg"
        media_store.valid?
        expect(media_store.output_url).to eq("http://example.com/existing_output.jpg")
      end
    end
  end
end
