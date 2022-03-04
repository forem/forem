require "rails_helper"

RSpec.describe Notifications::Milestone::Send, type: :service do
  def send_milestone_notification_view
    described_class.call("View", article)
  end

  def send_milestone_notification_reaction
    described_class.call("Reaction", article)
  end

  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id, page_views_count: 4000, public_reactions_count: 70) }

  context "when a user has never received a milestone notification" do
    it "sends the appropriate level view milestone notification" do
      send_milestone_notification_view
      expect(user.notifications.first.action).to include "2048"
    end

    it "sends the appropriate level reaction milestone notification" do
      send_milestone_notification_reaction
      expect(user.notifications.first.action).to include "64"
    end
  end

  context "when a user has received a milestone notification before" do
    def mock_previous_view_milestone_notification
      send_milestone_notification_view
      article.update_column(:page_views_count, 9001)
      send_milestone_notification_view
    end

    def mock_previous_reaction_milestone_notification
      send_milestone_notification_reaction
      article.update_column(:public_reactions_count, 150)
      send_milestone_notification_reaction
    end

    describe "When send view type milestone notification" do
      before do
        mock_previous_view_milestone_notification
      end

      it "sends the appropriate level view milestone notification" do
        expect(user.notifications.second.action).to include "8192"
      end

      it "adds an additional view milestone notification" do
        expect(user.notifications.count).to eq 2
      end

      it "does not the same view milestone notification if called again" do
        send_milestone_notification_view
        expect(user.notifications.count).to eq 2
      end

      it "does not send a view milestone notification again if the latest num of views isn't past the next milestone" do
        article.update_column(:page_views_count, rand(9002..16_383))
        send_milestone_notification_view
        expect(user.notifications.count).to eq 2
      end

      it "checks notification json data", :aggregate_failures do
        nots = user.notifications
        expect(nots.where(notifiable_type: "Article").first.json_data["article"]["class"]["name"]).to eq("Article")
        expect(nots.where(notifiable_id: article.id).first.json_data["article"]["id"]).to eq(article.id)
        expect(nots.where(notifiable_id: article.id).first.json_data["article"]["title"]).to eq(article.title)
      end
    end

    it "sends the appropriate level reaction milestone notification" do
      mock_previous_reaction_milestone_notification
      expect(user.notifications.last.action).to include "128"
    end

    context "when an article is related to an organization" do
      let(:organization) { create(:organization) }

      before { article.organization = organization }

      it "creates another notification related to organization" do
        coll = Notification.where(organization_id: article.organization_id)
        expect { send_milestone_notification_reaction }.to change { coll.count }.by(1)
      end
    end
  end
end
