require "rails_helper"

# Regression for forem/forem#23266: initScrolling.js (lines 394-396) anchors
# pagination on `querySelectorAll('.single-article, .crayons-story')`'s last
# match, which can be a quickie's embed inner card — dropping `.paged-stories`
# inside `.ltag__link--embedded`.
RSpec.describe "Quickie embed feed engulfment (#23266)", :js do
  before do
    # Page-of-1 keeps the quickie alone on page 1 (so its embed is the
    # trailing `.crayons-story`) and spills `target` to page 2.
    stub_const("Article::DEFAULT_FEED_PAGINATION_WINDOW_SIZE", 1)

    # /latest applies both filters (stories_controller.rb:370-373).
    min_score = [Settings::UserExperience.home_feed_minimum_score,
                 Settings::UserExperience.index_minimum_score].max + 1
    user = create(:user)

    # Embed target + page-2 content (older than the quickie).
    target = create(:article, :past, past_published_at: 10.hours.ago, score: min_score, user: user)

    # Build directly: the factory's `title` transient only writes to
    # body_markdown frontmatter, but `add_urls_from_title_to_body`
    # (article.rb:1702) needs a URL in the title *column* to inject the embed.
    quickie = Article.new(
      user: user,
      type_of: "status",
      title: "Look at this #{URL.article(target)}",
      body_markdown: "",
      main_image: nil,
      published: true,
    )
    quickie.save!
    quickie.update_columns(published_at: 1.hour.ago, score: min_score)
  end

  it "does not nest paginated feed cards inside the quickie embed" do
    visit "/latest"

    expect(page).to have_css(".ltag__link--embedded", wait: 5)
    # Guard against vacuous pass: pagination must have fired.
    expect(page).to have_css(".paged-stories", wait: 10, visible: :all)

    # `visible: :all` because the embed's CSS hides engulfed descendants.
    expect(page).to have_no_css(".ltag__link--embedded .paged-stories", visible: :all)
  end
end
