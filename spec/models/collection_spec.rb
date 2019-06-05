require "rails_helper"

RSpec.describe Collection, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:collection) { create(:collection, :with_articles, user_id: user.id) }

  describe "when a single article in collection is updated" do
    it "touches all articles in the collection" do
      article = collection.articles.sample
      duration = 3.days

      old_times = collection.articles.map { |a| a.updated_at.to_i }
      new_times = old_times.map { |t| (t + duration).to_i }

      travel(duration) do
        expect do
          article.touch
        end.to change { collection.reload.articles.map { |a| a.updated_at.to_i } }.from(old_times).to(new_times)
      end
    end
  end
end
