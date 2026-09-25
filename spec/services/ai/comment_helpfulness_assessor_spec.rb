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
           body_markdown: "---\ntitle: Welcome Thread\npublished: true\ntags: welcome\n---\n\nWelcome to our community! Introduce yourself below.")
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

  describe "#helpful? with Jev selected" do
    before { enable_jev_for(:comment_helpfulness) }

    context "with a top-level comment" do
      it "qualifies substantive help for newcomers" do
        requests = stub_jev(helps_newcomers: 0.9)

        expect(assessor.helpful?).to be(true)
        expect(requests.first[:questions].keys).to contain_exactly(:low_effort, :spam_or_promotion, :helps_newcomers)
        expect(requests.first[:state]).not_to have_key(:replying_to)
      end

      it "rejects low-effort comments even when they are welcoming" do
        stub_jev(helps_newcomers: 0.9, low_effort: 0.6)

        expect(assessor.helpful?).to be(false)
      end

      it "rejects uncertain help" do
        stub_jev(helps_newcomers: 0.6)

        expect(assessor.helpful?).to be(false)
      end
    end

    context "with a reply" do
      let(:parent) { create(:comment, commentable: welcome_thread, body_markdown: "Hi! I'm new to Rust, any tips?") }
      let(:comment) do
        create(:comment, commentable: welcome_thread, parent: parent, body_markdown: "Try the Rust book, it's great!")
      end

      it "requires the reply to engage with its parent and add value" do
        requests = stub_jev(engages_with_parent: 0.9, adds_value: 0.9)

        expect(assessor.helpful?).to be(true)
        expect(requests.first[:state][:replying_to]).to eq(parent.body_markdown)

        stub_jev(engages_with_parent: 0.9, adds_value: 0.3)
        expect(described_class.new(comment, welcome_thread).helpful?).to be(false)
      end
    end
  end
end
