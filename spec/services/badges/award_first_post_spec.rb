require "rails_helper"

RSpec.describe Badges::AwardFirstPost do
  describe ".call" do
    before do
      create(:badge, title: "Writing Debut")
    end

    after do
      Timecop.return
    end

    context "when the article is created outside the award window" do
      it "does not award the badge for an article created more than a week ago" do
        Timecop.freeze(2.weeks.ago) do
          create(:article)
        end
        Timecop.return
        expect { described_class.call }.not_to change(BadgeAchievement, :count)
      end

      it "does not award the badge for an article created less than an hour ago" do
        create(:article)
        expect { described_class.call }.not_to change(BadgeAchievement, :count)
      end
    end

    context "when the article is created within the award window" do
      it "awards the badge" do
        Timecop.freeze(2.days.ago) do
          create(:article, user: create(:user))
        end
        Timecop.return
        expect { described_class.call }.to change(BadgeAchievement, :count).by(1)
      end

      it "does not award the badge if the article score is less than zero" do
        Timecop.freeze(2.days.ago) do
          create(:article, user: create(:user), score: -1)
        end
        Timecop.return
        expect { described_class.call }.not_to change(BadgeAchievement, :count)
      end
    end

    context "when the user has a spam or suspended role" do
      it "does not award the badge to a spam user" do
        user = create(:user).tap { |u| u.add_role(:spam) }
        Timecop.freeze(2.days.ago) do
          create(:article, user: user)
        end
        Timecop.return
        expect { described_class.call }.not_to change(BadgeAchievement, :count)
      end

      it "does not award the badge to a suspended user" do
        user = create(:user).tap { |u| u.add_role(:suspended) }
        Timecop.freeze(2.days.ago) do
          create(:article, user: user)
        end
        Timecop.return
        expect { described_class.call }.not_to change(BadgeAchievement, :count)
      end
    end
  end
end
