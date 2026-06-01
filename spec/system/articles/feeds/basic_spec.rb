require "rails_helper"

RSpec.describe Articles::Feeds::Basic, :js do
  let(:user) { create(:user) }
  let(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago)
  end

  before do
    create(:article, hotness_score: 10)
  end

  context "with a user" do
    let(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }

    it "doesn't display blocked articles", :js, type: :system do
      selector = "article[data-content-user-id='#{hot_story.user_id}']"
      sign_in user
      visit root_path

      # Assert presence with a retry loop to prevent Ferrum NodeNotFound crashes
      # during active Preact DOM repaints on high-priority feed requests.
      retry_count = 0
      begin
        expect(page).to have_selector(selector)
      rescue Ferrum::NodeNotFoundError, RSpec::Expectations::ExpectationNotMetError => e
        retry_count += 1
        raise e unless retry_count < 10

        sleep 0.2
        retry
      end

      # Use find_or_create_by to prevent uniqueness validation errors if the spec is retried
      UserBlock.find_or_create_by!(blocker: user, blocked: hot_story.user, config: "default")
      visit root_path

      # Assert absence/invisibility with a retry loop to prevent Ferrum NodeNotFound crashes
      retry_count = 0
      begin
        expect(page).to have_no_selector(selector, visible: :visible)
      rescue Ferrum::NodeNotFoundError => e
        retry_count += 1
        raise e unless retry_count < 10

        sleep 0.2
        retry
      end
    end
  end
end
