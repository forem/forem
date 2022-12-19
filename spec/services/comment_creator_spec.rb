require "rails_helper"

RSpec.describe CommentCreator, type: :service do
  subject(:creator) { described_class.build_comment params, current_user: user }

  let(:user) { create :user }
  let(:commentable) { create :article }
  let(:record) { Comment.new user: user }
  let(:params) do
    {
      commentable_id: commentable.id,
      commentable_type: commentable.class_name.to_s,
      body_markdown: "Hi, there!"
    }
  end

  before do
    allow(Comment).to receive(:build_comment).and_return(record)
    allow(NotificationSubscription).to receive(:create)
    allow(Notification).to receive(:send_new_comment_notifications_without_delay)
    allow(Mention).to receive(:create_all)
    allow(Reaction).to receive(:create)

    allow(user).to receive(:comments)
  end

  it "responds as if Comment" do
    methods = Comment.instance_methods - [:save]
    methods.each do |method_name|
      expect(creator).to respond_to(method_name)
    end
  end

  context "when save is successful" do
    before do
      allow(record).to receive(:save).and_return(true)
      creator.save
    end

    it "notifies subscribers" do
      expect(NotificationSubscription).to have_received(:create)
      expect(Notification).to have_received(:send_new_comment_notifications_without_delay)
      expect(Mention).to have_received(:create_all)
    end

    it "creates a new reaction" do
      expect(Reaction).to have_received(:create)
    end
  end

  context "when save is unsuccessful" do
    before do
      allow(record).to receive(:save).and_return(false)
      creator.save
    end

    it "does not notify subscribers" do
      expect(NotificationSubscription).not_to have_received(:create)
      expect(Notification).not_to have_received(:send_new_comment_notifications_without_delay)
      expect(Mention).not_to have_received(:create_all)
    end

    it "does not create a new reaction" do
      expect(Reaction).not_to have_received(:create)
    end
  end
end
