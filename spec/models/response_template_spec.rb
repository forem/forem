require "rails_helper"

RSpec.describe ResponseTemplate do
  let(:comment_validation_message) { I18n.t("models.response_template.comment_markdown") }

  it { is_expected.to validate_inclusion_of(:type_of).in_array(ResponseTemplate::TYPE_OF_TYPES) }
  it { is_expected.to validate_inclusion_of(:content_type).in_array(ResponseTemplate::CONTENT_TYPES) }

  describe "comment content type validation" do
    context "when the type of is a personal comment" do
      it "validates that the content type is body markdown" do
        response_template = build(:response_template, type_of: "personal_comment", content_type: "html")
        expect(response_template.valid?).to be false
        expect(response_template.errors.messages[:content_type].to_sentence).to eq(comment_validation_message)
      end
    end

    context "when the type of is a mod comment" do
      it "validates that the content type is body markdown" do
        response_template = build(:response_template, type_of: "mod_comment", content_type: "html")
        expect(response_template.valid?).to be false
        expect(response_template.errors.messages[:content_type].to_sentence).to eq(comment_validation_message)
      end

      it "validates that there is no user ID associated" do
        response_template = build(:response_template, type_of: "mod_comment", content_type: "body_markdown", user_id: 1)
        expect(response_template.valid?).to be false
        expect(response_template.errors.messages[:type_of].to_sentence).to eq(
          I18n.t("models.response_template.user_nil_only"),
        )
      end
    end
  end

  describe "user validation" do
    it "validates the number of templates for a normal user" do
      user = create(:user)
      create_list(:response_template, 30, user_id: user.id)
      invalid_template = create(:response_template, user_id: user.id)

      expect(invalid_template).not_to be_valid
      expect(invalid_template.errors.full_messages.join).to include("limit of 30 per user has been reached")
    end

    it "allows trusted users to have unlimited templates" do
      user = create(:user, :trusted)
      create_list(:response_template, 31, user_id: user.id)

      expect(user.response_templates.all?(&:valid?)).to be(true)
    end
  end
end
