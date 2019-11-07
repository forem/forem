require "rails_helper"

RSpec.describe TagAdjustmentCreationService do
  let(:user) { create(:user) }
  let(:article) { create(:article, tags: tag.name) }
  let(:tag) { create(:tag) }

  def create_tag_adjustment(type)
    described_class.new(
      user,
      adjustment_type: type,
      status: "committed",
      tag_name: tag.name,
      article_id: article.id,
      reason_for_adjustment: "Test",
    ).create
  end

  before do
    user.add_role(:tag_moderator, tag)
  end

  describe "creates tag adjustment" do
    it "with adjustment_type removal" do
      tag_adjustment = create_tag_adjustment("removal")
      expect(tag_adjustment).to be_valid
      expect(tag_adjustment.tag_id).to eq(tag.id)
      expect(tag_adjustment.status).to eq("committed")
    end

    it "with adjustment_type addition" do
      tag_adjustment = create_tag_adjustment("addition")

      expect(tag_adjustment).to be_valid
      expect(tag_adjustment.tag_id).to eq(tag.id)
      expect(tag_adjustment.status).to eq("committed")
    end
  end

  describe "creates notification" do
    it "with adjustment_type removal" do
      perform_enqueued_jobs do
        tag_adjustment = create_tag_adjustment("removal")
        expect(Notification.last.user_id).to eq(article.user_id)
        expect(Notification.last.json_data["adjustment_type"]).to eq(tag_adjustment.adjustment_type)
      end
    end

    it "with adjustment_type addition" do
      perform_enqueued_jobs do
        tag_adjustment = create_tag_adjustment("addition")
        expect(Notification.last.user_id).to eq(article.user_id)
        expect(Notification.last.json_data["adjustment_type"]).to eq(tag_adjustment.adjustment_type)
      end
    end
  end
end
