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
    def seed_response_templates(user_id, count)
      now = Time.current
      records = Array.new(count) do |i|
        {
          user_id: user_id,
          title: "Template #{i}",
          content: "Template content #{i}",
          type_of: "personal_comment",
          content_type: "body_markdown",
          created_at: now,
          updated_at: now
        }
      end
      ResponseTemplate.insert_all!(records)
    end

    it "validates the number of templates for a normal user", :aggregate_failures do
      user = create(:user)
      seed_response_templates(user.id, 31)
      invalid_template = build(:response_template, user: user)

      expect(invalid_template).not_to be_valid
      expect(invalid_template.errors.full_messages.join).to include("limit of 30 per user has been reached")
    end

    it "allows trusted users to have unlimited templates" do
      user = create(:user, :trusted)
      seed_response_templates(user.id, 31)
      valid_template = build(:response_template, user: user)

      expect(valid_template).to be_valid
    end
  end
end
