require "rails_helper"

RSpec.describe FeedEvent do
  describe "validations" do
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to validate_numericality_of(:article_id).only_integer }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to validate_numericality_of(:user_id).only_integer.allow_nil }

    it { is_expected.to define_enum_for(:category).with_values(%i[impression click reaction comment]) }
    it { is_expected.to validate_numericality_of(:article_position).is_greater_than(0).only_integer }
    it { is_expected.to validate_inclusion_of(:context_type).in_array(%w[home search tag]) }
  end

  describe ".record_journey_for" do
    subject(:record_journey) { described_class.record_journey_for(user, article: article, category: category) }

    let(:article) { create(:article) }
    let(:user) { create(:user) }
    let(:category) { :reaction }

    it "records a feed event if the user's last click was on the specified article" do
      click = create(:feed_event, user: user, article: article, category: :click)

      expect { record_journey }.to change(described_class, :count).by(1)
      expect(user.feed_events.last).to have_attributes(
        category: "reaction",
        article_id: article.id,
        user_id: user.id,
        context_type: click.context_type,
        article_position: click.article_position,
      )
    end

    it "does not record a feed event if the user has no feed events for the specified article" do
      expect { record_journey }.not_to change(described_class, :count)
      expect(user.feed_events).to be_empty
    end

    it "does not record a feed event if the user did not click through from the feed" do
      impression = create(:feed_event, user: user, article: article, category: :impression)

      expect { record_journey }.not_to change(described_class, :count)
      expect(user.feed_events).to contain_exactly(impression)
    end

    it "does not record a feed event if the user's last click was not on the specified article" do
      click = create(:feed_event, user: user, article: article, category: :click)
      other_click = create(:feed_event, user: user, category: :click)

      expect { record_journey }.not_to change(described_class, :count)
      expect(user.feed_events).to contain_exactly(click, other_click)
    end

    context "when the interaction is not a comment or reaction" do
      let(:category) { :impression }

      it "does not record a feed event" do
        click = create(:feed_event, user: user, article: article, category: :click)

        expect { record_journey }.not_to change(described_class, :count)
        expect(user.feed_events).to contain_exactly(click)
      end
    end
  end
end
