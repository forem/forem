require "rails_helper"

RSpec.describe Articles::Feeds::LargeForemExperimental, :js do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let!(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user_id: second_user.id)
  end

  before do
    create(:article)
  end

  it "doesn't display blocked articles" do
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
