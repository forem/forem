require "rails_helper"

RSpec.describe Ai::CommentHelpfulnessAssessor, type: :service do
  let(:admin_user) { create(:user, :super_admin) }
  let(:welcome_thread) do
    create(:article, :past,
           user: admin_user,
           published: true,
           past_published_at: 2.weeks.ago,
           tag_list: "welcome",
           title: "Welcome Thread",
           body_markdown: "Welcome to our community! Introduce yourself below.")
  end
  let(:comment) do
    create(:comment,
           user: create(:user),
           commentable: welcome_thread,
           body_markdown: "Welcome! Here are some tips to get started...")
  end
  let(:assessor) { described_class.new(comment, welcome_thread) }

  describe "#helpful?" do
    context "when AI returns YES" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("YES")
      end

      it "returns true" do
        expect(assessor.helpful?).to be(true)
      end
    end

    context "when AI returns NO" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("NO")
      end

      it "returns false" do
        expect(assessor.helpful?).to be(false)
      end
    end

    context "when AI returns yes (lowercase)" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("yes")
      end

      it "returns true" do
        expect(assessor.helpful?).to be(true)
      end
    end

    context "when AI returns a response containing YES" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("The comment is helpful. YES, it qualifies.")
      end

      it "returns true" do
        expect(assessor.helpful?).to be(true)
      end
    end

    context "when AI raises an error" do
      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_raise(StandardError, "API error")
      end

      it "returns false and logs error" do
        expect(Rails.logger).to receive(:error).with(/Comment Helpfulness Assessment failed/)
        expect(assessor.helpful?).to be(false)
      end
    end

    context "with top-level comment" do
      let(:top_level_comment) do
        create(:comment,
               user: create(:user),
               commentable: welcome_thread,
               body_markdown: "Welcome! Here are some helpful tips...",
               parent_id: nil)
      end
      let(:assessor) { described_class.new(top_level_comment, welcome_thread) }

      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("YES")
      end

      it "builds prompt with top-level context" do
        expect(assessor.helpful?).to be(true)
      end
    end

    context "with reply comment" do
      let(:parent_comment) do
        create(:comment,
               user: create(:user),
               commentable: welcome_thread,
               body_markdown: "I'm new here!")
      end
      let(:reply_comment) do
        create(:comment,
               user: create(:user),
               commentable: welcome_thread,
               parent: parent_comment,
               body_markdown: "Welcome! Here's how to get started...")
      end
      let(:assessor) { described_class.new(reply_comment, welcome_thread) }

      before do
        allow_any_instance_of(Ai::Base).to receive(:call).and_return("YES")
      end

      it "builds prompt with parent comment context" do
        expect(assessor.helpful?).to be(true)
      end
    end
  end
end

