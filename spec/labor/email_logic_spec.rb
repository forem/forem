require "rails_helper"

RSpec.describe EmailLogic, type: :labor do
  let(:user) { create(:user) }

  describe "#analyze" do
    context "when user is brand new with no-follow" do
      it "returns 0.5 for open_percentage" do
        author = create(:user)
        user.follow(author)
        create_list(:article, 3, user_id: author.id, positive_reactions_count: 20, score: 20)
        h = described_class.new(user).analyze
        expect(h.open_percentage).to eq(0.5)
      end

      it "provides top 3 articles" do
        create_list(:article, 3, positive_reactions_count: 40, featured: true, score: 40)
        h = described_class.new(user).analyze
        expect(h.articles_to_send.length).to eq(3)
      end

      it "marks as not ready if there isn't atleast 3 articles" do
        create_list(:article, 2, positive_reactions_count: 40, score: 40)
        h = described_class.new(user).analyze
        expect(h.should_receive_email?).to eq(false)
      end

      it "marks as not ready if there isn't at least 3 email-digest-eligible articles" do
        create_list(:article, 2, positive_reactions_count: 40, score: 40)
        create_list(:article, 2, positive_reactions_count: 40, email_digest_eligible: false)
        h = described_class.new(user).analyze
        expect(h.should_receive_email?).to eq(false)
      end
    end

    context "when a user's open_percentage is low " do
      before do
        author = create(:user)
        user.follow(author)
        create_list(:article, 3, user_id: author.id, positive_reactions_count: 20, score: 20)
        10.times do
          Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                               user_id: user.id, sent_at: Time.current.utc)
        end
      end

      it "will not send email when user shouldn't receive any" do
        h = described_class.new(user).analyze
        expect(h.should_receive_email?).to eq(false)
      end
    end

    context "when a user's open_percentage is high" do
      before do
        10.times do
          Ahoy::Message.create(mailer: "DigestMailer#digest_email", user_id: user.id,
                               sent_at: Time.current.utc, opened_at: Time.current.utc)
          author = create(:user)
          user.follow(author)
          create_list(:article, 3, user_id: author.id, positive_reactions_count: 40, score: 40)
        end
      end

      it "evaluates that user is ready to receive an email" do
        Timecop.freeze(3.days.from_now) do
          h = described_class.new(user).analyze
          expect(h.should_receive_email?).to eq(true)
        end
      end
    end
  end

  describe "#should_receive_email?" do
    it "reflects @ready_to_receive_email" do
      author = create(:user)
      user.follow(author)
      create_list(:article, 3, user_id: author.id, positive_reactions_count: 20, score: 20)
      h = described_class.new(user).analyze
      expect(h.should_receive_email?).to eq(true)
    end
  end
end
