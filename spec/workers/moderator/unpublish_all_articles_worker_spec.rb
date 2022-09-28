require "rails_helper"

RSpec.describe Moderator::UnpublishAllArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  context "when unpublishing" do
    let!(:user) { create(:user) }
    let!(:admin) { create(:user, :admin) }

    before {  allow(Moderator::UnpublishAllArticles).to receive(:call) }

    it "calls UnpublishAllArticles" do
      described_class.new.perform(user.id, admin.id)
      expect(Moderator::UnpublishAllArticles).to have_received(:call).with(target_user_id: user.id,
                                                                           action_user_id: admin.id,
                                                                           listener: :admin_api)
    end

    it "calls UnpublishAllArticles with listener" do
      described_class.new.perform(user.id, admin.id, "moderator")
      expect(Moderator::UnpublishAllArticles).to have_received(:call).with(target_user_id: user.id,
                                                                           action_user_id: admin.id,
                                                                           listener: :moderator)
    end

    it "calls UnpublishAllArticles with the default listener" do
      described_class.new.perform(user.id, admin.id, "admin_api")
      expect(Moderator::UnpublishAllArticles).to have_received(:call).with(target_user_id: user.id,
                                                                           action_user_id: admin.id,
                                                                           listener: :admin_api)
    end

    it "calls UnpublishAllArticles with the default listener if passed invalid listener" do
      described_class.new.perform(user.id, admin.id, "another_api")
      expect(Moderator::UnpublishAllArticles).to have_received(:call).with(target_user_id: user.id,
                                                                           action_user_id: admin.id,
                                                                           listener: :admin_api)
    end
  end
end
