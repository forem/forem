require "rails_helper"

RSpec.describe Notifications::Update, type: :service do
  let_it_be(:article) { create(:article) }

  context "when updating notifications of an article" do
    it "updates all notifications with the same action", :aggregate_failures do
      notifications = create_list(:notification, 2, notifiable: article, action: "Published")

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(article, "Published")

      notifications.each(&:reload)

      notifications.each do |notification|
        expect(notification.json_data["article"]["id"]).to eq(article.id)
        expect(notification.json_data["user"]["id"]).to eq(article.user.id)
        expect(notification.json_data["organization"]).to be_nil
      end
    end

    it "does not update notifications with a different action" do
      notifications = create_list(:notification, 2, notifiable: article, action: nil)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(article, "Published")

      notifications.each(&:reload)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil
    end
  end

  context "when updating notifications of an organization article" do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:article) { create(:article, organization: organization) }

    it "updates all notifications with the same action", :aggregate_failures do
      notifications = create_list(:notification, 2, notifiable: article, action: "Published")

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(article, "Published")

      notifications.each(&:reload)

      notifications.each do |notification|
        expect(notification.json_data["article"]["id"]).to eq(article.id)
        expect(notification.json_data["user"]["id"]).to eq(article.user.id)
        expect(notification.json_data["organization"]["id"]).to eq(article.organization.id)
      end
    end

    it "does not update notifications with a different action" do
      notifications = create_list(:notification, 2, notifiable: article, action: nil)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(article, "Published")

      notifications.each(&:reload)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil
    end
  end

  context "when updating notifications on a comment" do
    let_it_be(:comment) { create(:comment, commentable: article) }

    it "updates all notifications", :aggregate_failures do
      notifications = create_list(:notification, 2, notifiable: comment)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(comment)

      notifications.each(&:reload)

      notifications.each do |notification|
        expect(notification.json_data["comment"]["id"]).to eq(comment.id)
        expect(notification.json_data["user"]["id"]).to eq(comment.user.id)
        expect(notification.json_data["organization"]).to be_nil
      end
    end
  end

  context "when updating notifications on a reaction" do
    let_it_be(:reaction) { create(:reaction, reactable: article) }

    it "does not update notifications", :aggregate_failures do
      notifications = create_list(:notification, 2, notifiable: reaction)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil

      described_class.call(reaction)

      notifications.each(&:reload)

      expect(notifications.first.json_data).to be_nil
      expect(notifications.last.json_data).to be_nil
    end
  end
end
