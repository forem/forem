require "rails_helper"

RSpec.describe TagAdjustmentCreationService, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, tags: tag.name) }
  let(:tag) { create(:tag) }

  def create_service(type)
    described_class.new(
      user,
      adjustment_type: type,
      status: "committed",
      tag_name: tag.name,
      article_id: article.id,
    )
  end

  before do
    user.add_role(:tag_moderator, tag)
  end

  describe "creates tag adjustment" do
    it "with adjustment_type removal" do
      tag_adjustment = create_service("removal").tag_adjustment
      tag_adjustment.save
      expect(tag_adjustment).to be_valid
      expect(tag_adjustment.tag_id).to eq(tag.id)
      expect(tag_adjustment.status).to eq("committed")
    end

    it "with adjustment_type addition" do
      tag_adjustment = create_service("addition").tag_adjustment
      tag_adjustment.save
      expect(tag_adjustment).to be_valid
      expect(tag_adjustment.tag_id).to eq(tag.id)
      expect(tag_adjustment.status).to eq("committed")
    end
  end

  describe "creates notification" do
    it "with adjustment_type removal" do
      service = create_service("removal")
      tag_adjustment = service.tag_adjustment
      tag_adjustment.save

      sidekiq_perform_enqueued_jobs do
        service.update_tags_and_notify
      end

      tag_adjustment.reload
      last_tag_adjustment = tag_adjustment.notifications.last

      expect(last_tag_adjustment.user_id).to eq(article.user_id)
      expect(last_tag_adjustment.json_data["adjustment_type"]).to eq(tag_adjustment.adjustment_type)
    end

    it "with adjustment_type addition" do
      service = create_service("addition")
      tag_adjustment = service.tag_adjustment
      tag_adjustment.save

      sidekiq_perform_enqueued_jobs do
        service.update_tags_and_notify
      end

      tag_adjustment.reload
      last_tag_adjustment = tag_adjustment.notifications.last

      expect(last_tag_adjustment.user_id).to eq(article.user_id)
      expect(last_tag_adjustment.json_data["adjustment_type"]).to eq(tag_adjustment.adjustment_type)
    end
  end
end
