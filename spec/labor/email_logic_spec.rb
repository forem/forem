require "rails_helper"

RSpec.describe EmailLogic do
  let(:user) { create(:user) }

  # TODO: improve this test suite, and improve it's speed

  describe "#analyze" do
    context "when user is brand new with no-follow" do
      it "returns 0.5 for open_percentage" do
        author = create(:user)
        user.follow(author)
        3.times { create(:article, user_id: author.id, positive_reactions_count: 20) }
        h = described_class.new(user).analyze
        expect(h.open_percentage).to eq(0.5)
      end

      it "provides top 3 articles" do
        3.times { create(:article, positive_reactions_count: 40, featured: true) }
        h = described_class.new(user).analyze
        expect(h.articles_to_send.length).to eq(3)
      end

      it "marks as not ready if there isn't atleast 3 articles" do
        2.times { create(:article, positive_reactions_count: 40) }
        h = described_class.new(user).analyze
        expect(h.should_receive_email?).to eq(false)
      end
    end

    context "when a user's open_percentage is low " do
      before do
        author = create(:user)
        user.follow(author)
        3.times { create(:article, user_id: author.id, positive_reactions_count: 20) }
        10.times do
          Ahoy::Message.create(mailer: "DigestMailer#digest_email",
                               user_id: user.id, sent_at: Time.now.utc)
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
                               sent_at: Time.now.utc, opened_at: Time.now.utc)
          author = create(:user)
          user.follow(author)
          3.times { create(:article, user_id: author.id, positive_reactions_count: 40) }
        end
      end

      it "evaluates that user is ready to recieve an email" do
        Timecop.freeze(Date.today + 3) do
          h = described_class.new(user).analyze
          expect(h.should_receive_email?).to eq(true)
        end
      end
    end
  end

  describe "#should_receive_email?" do
    it "refelcts @ready_to_receive_email" do
      author = create(:user)
      user.follow(author)
      3.times { create(:article, user_id: author.id, positive_reactions_count: 20) }
      h = described_class.new(user).analyze
      expect(h.should_receive_email?).to eq(true)
    end
  end
end
