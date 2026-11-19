require "rails_helper"

RSpec.describe Comment do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:event_resource_admin) do
    create(:user).tap { |u| u.add_role(:single_resource_admin, Event) }
  end

  let(:live_event) do
    create(:event, published: true, allow_comments: true,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end
  let(:upcoming_event) do
    create(:event, published: true, allow_comments: true,
                   start_time: 1.hour.from_now, end_time: 3.hours.from_now)
  end
  let(:ended_event) do
    create(:event, published: true, allow_comments: true,
                   start_time: 3.hours.ago, end_time: 1.hour.ago)
  end
  let(:draft_live_event) do
    create(:event, published: false, allow_comments: true,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end
  let(:disabled_live_event) do
    create(:event, published: true, allow_comments: false,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end

  describe "event commentable validations and counter cache" do
    it "includes Event in Comment::COMMENTABLE_TYPES" do
      expect(Comment::COMMENTABLE_TYPES).to include("Event")
    end

    it "allows regular users to comment and reply during a published live event with allow_comments enabled" do
      root_comment = create(:comment, user: user, commentable: live_event, body_markdown: "Hello hallway!")
      reply = create(:comment, user: create(:user), commentable: live_event, parent: root_comment,
                               body_markdown: "Welcome!")

      expect(root_comment).to be_persisted
      expect(reply.parent).to eq(root_comment)
      expect(live_event.reload.comments_count).to eq(2)
      expect(root_comment.descendants).to contain_exactly(reply)
    end

    it "decrements events.comments_count when an event comment is soft-deleted or destroyed" do
      comment = create(:comment, user: user, commentable: live_event, body_markdown: "Hallway note")
      expect(live_event.reload.comments_count).to eq(1)

      comment.update!(deleted: true)
      expect(live_event.reload.comments_count).to eq(0)

      second = create(:comment, user: user, commentable: live_event, body_markdown: "Second hallway note")
      expect(live_event.reload.comments_count).to eq(1)

      second.destroy!
      expect(live_event.reload.comments_count).to eq(0)
    end

    it "rejects commenting when event has allow_comments disabled for both regular users and admins" do
      regular = build(:comment, user: user, commentable: disabled_live_event)
      by_admin = build(:comment, user: admin, commentable: disabled_live_event)
      via_console = build(:comment, user: user, commentable: disabled_live_event, admin_update: true)

      [regular, by_admin, via_console].each do |comment|
        expect(comment).not_to be_valid
        expect(comment.errors[:commentable_id]).to include(I18n.t("models.comment.event_comments_disabled"))
      end
    end

    it "rejects regular users commenting before, after, or on an unpublished event" do
      [upcoming_event, ended_event, draft_live_event].each do |event|
        comment = build(:comment, user: user, commentable: event)
        expect(comment).not_to be_valid
        expect(comment.errors[:commentable_id]).to include(I18n.t("models.comment.event_not_accepting_comments"))
      end
    end

    it "allows admins (super_admin, event resource admin, or admin_update) before, during, after, and on drafts" do
      [upcoming_event, live_event, ended_event, draft_live_event].each do |event|
        expect(build(:comment, user: admin, commentable: event)).to be_valid
        expect(build(:comment, user: event_resource_admin, commentable: event)).to be_valid
        expect(build(:comment, user: user, commentable: event, admin_update: true)).to be_valid
      end
    end

    it "allows editing and soft-deleting an existing event comment after the event ends or disables comments" do
      comment = create(:comment, user: user, commentable: live_event, body_markdown: "Initial note")
      live_event.update!(start_time: 3.hours.ago, end_time: 1.hour.ago, allow_comments: false)

      expect(comment.update(body_markdown: "Edited note")).to be(true)
      expect(comment.update(deleted: true)).to be(true)
    end

    it "formats a missing Event commentable error with the localized Event label" do
      comment = build(:comment, user: user, commentable: nil, commentable_type: "Event")
      comment.validate

      expect(comment).not_to be_valid
      expect(comment.errors_as_sentence).to include("Event has been deleted.")
    end
  end

  describe "visibility, search indexing, and ecosystem safety" do
    it "hides pre-event, draft-event, and disabled-event comments from visible_event and Algolia" do
      pre_event_comment = create(:comment, user: admin, commentable: upcoming_event)
      draft_comment = create(:comment, user: admin, commentable: draft_live_event)
      live_comment = create(:comment, user: user, commentable: live_event)
      ended_comment = create(:comment, user: admin, commentable: ended_event)

      expect(pre_event_comment).to have_attributes(visible_event: nil, event_visible?: false, bad_comment?: true)
      expect(draft_comment).to have_attributes(visible_event: nil, bad_comment?: true)
      expect(live_comment).to have_attributes(visible_event: live_event, event_visible?: true, bad_comment?: false)
      expect(ended_comment).to have_attributes(visible_event: ended_event, bad_comment?: false)

      live_event.update!(allow_comments: false)
      expect(live_comment.reload).to have_attributes(visible_event: nil, bad_comment?: true)
    end

    it "does not send reply email notifications for hidden pre-event comments" do
      other_admin = create(:user, :super_admin)
      allow(Comments::SendEmailNotificationWorker).to receive(:perform_in)

      parent_comment = create(:comment, user: admin, commentable: upcoming_event, body_markdown: "Pre-event root")
      create(:comment, user: other_admin, commentable: upcoming_event, parent: parent_comment,
                       body_markdown: "Pre-event reply")

      expect(Comments::SendEmailNotificationWorker).not_to have_received(:perform_in)
    end

    it "handles hostless events without crashing notifications, cache busting, or AI spam prompt building" do
      hostless_event = create(:event, user: nil, body_markdown: nil, published: true, allow_comments: true,
                                      start_time: 1.hour.ago, end_time: 1.hour.from_now)
      comment = create(:comment, user: user, commentable: hostless_event, body_markdown: "Great session at 01:30!")

      expect(comment.subforem_id).to be_nil
      expect(Notification.send_new_comment_notifications_without_delay(comment)).to be_nil
      expect { Notification.send_moderation_notification(comment) }.not_to raise_error
      expect { EdgeCache::BustComment.call(comment) }.not_to raise_error

      allow(Ai::FunctionConfig).to receive(:selection_for).and_return(
        instance_double(Ai::FunctionConfig::Selection, decision?: false, gemini_model: "gemini-2.5-flash"),
      )
      allow(Ai::Base).to receive(:new)
      prompt = Ai::CommentCheck.new(comment).__send__(:build_prompt)
      expect(prompt).to include(hostless_event.title)
    end
  end
end
