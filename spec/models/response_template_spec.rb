require "rails_helper"

RSpec.describe ResponseTemplate, type: :model do
  it { is_expected.to validate_inclusion_of(:type_of).in_array(ResponseTemplate::TYPE_OF_TYPES) }
  it { is_expected.to validate_inclusion_of(:content_type).in_array(ResponseTemplate::CONTENT_TYPES) }

  describe "comment content type validation" do
    context "when the type of is a personal comment" do
      it "validates that the content type is body markdown" do
        response_template = build(:response_template, type_of: "personal_comment", content_type: "html")
        expect(response_template.valid?).to eq false
        expect(response_template.errors.messages[:content_type].to_sentence).to eq ResponseTemplate::COMMENT_VALIDATION_MSG
      end
    end

    context "when the type of is a mod comment" do
      it "validates that the content type is body markdown" do
        response_template = build(:response_template, type_of: "mod_comment", content_type: "html")
        expect(response_template.valid?).to eq false
        expect(response_template.errors.messages[:content_type].to_sentence).to eq ResponseTemplate::COMMENT_VALIDATION_MSG
      end
    end
  end
end
