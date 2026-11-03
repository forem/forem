require "rails_helper"

RSpec.describe "Views an article" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  before do
    sign_in user
  end

  def expect_edit_link_hidden_from_non_authors(path)
    sign_out user
    visit path
    expect(page.body).not_to include("Click to edit")

    sign_in create(:user)
    visit path
    expect(page.body).to include('display: none;">Click to edit</a>')
  end

  it "stops a user from moderating an article" do
    # TODO: @maetromac this spec must run first to pass. Due to the usage of RequestStore, there's a false positive
    # with EdgeSafetyCheck. Reason is yet to be determined.
    expect { visit("/#{user.username}/#{article.slug}/mod") }.to raise_error(Pundit::NotAuthorizedError)
  end

  it "shows an article" do
    visit article.path
    expect(page).to have_content(article.title)
  end

  it "shows non-negative comments" do
    comments = Array.new(4) do |i|
      create(:comment, commentable: article, user: user, body_markdown: "Comment body #{i}")
    end
    admin = create(:user, :admin)
    create(:thumbsdown_reaction, reactable: comments.last, user: admin)
    sidekiq_perform_enqueued_jobs

    visit article.path
    expect(page).to have_css(".single-comment-node", visible: :visible, count: 4)

    sign_out user
    visit article.path
    expect(page).to have_css(".single-comment-node", visible: :visible, count: 3)
  end

  describe "sticky nav sidebar" do
    it "suggests articles by other users if the author has no other articles" do
      create(:article, user: create(:user))
      visit article.path
      expect(page).to have_text("Trending on #{Settings::Community.community_name}")
    end

    it "suggests more articles by the author if there are any" do
      create(:article, user: user)
      visit article.path
      expect(page).to have_text("More from #{user.name}")
    end
  end

  describe "when showing the date" do
    # TODO: @sre ideally this spec should have js:true enabled since we use
    # js helpers to ensure the datetime is locale. However, testing locale
    # datetimes has proven to be very flaky which is why the js is not included
    # here
    it "shows the readable publish date and embeds the published timestamp", :aggregate_failures do
      visit article.path

      expect(page).to have_css("article time", text: article.readable_publish_date.gsub("  ", " "))
      selector = "article time[datetime='#{article.decorate.published_timestamp}']"
      expect(page).to have_css(selector)
    end

    context "when articles have long markdowns and different published dates" do
      let(:first_article) { build(:article) }
      let(:second_article) { build(:article) }

      before do
        [first_article, second_article].each do |article|
          additional_characters_length = (ArticleDecorator::LONG_MARKDOWN_THRESHOLD + 1) - article.body_markdown.length
          article.body_markdown << Faker::Hipster.paragraph_by_chars(characters: additional_characters_length)
          article.save!
        end
      end

      # TODO: @sre ideally this spec should have js:true enabled since we use
      # js helpers to ensure the datetime is locale. However, testing locale
      # datetimes has proven to be very flaky which is why the js is not included
      # here
      it "shows the identical readable publish dates in each page" do
        visit first_article.path
        expect(page).to have_css("article time", text: first_article.readable_publish_date.gsub("  ", " "))
        expect(page).to have_css(".crayons-card--secondary time",
                                 text: first_article.readable_publish_date.gsub("  ", " "))
        visit second_article.path
        expect(page).to have_css("article time", text: second_article.readable_publish_date.gsub("  ", " "))
        expect(page).to have_css(".crayons-card--secondary time",
                                 text: second_article.readable_publish_date.gsub("  ", " "))
      end
    end
  end

  describe "when articles belong to a collection" do
    let(:collection) { create(:collection, user: user) }
    let(:articles_selector) { "//div[@class='series-switcher__list']//a" }

    context "with regular articles" do
      it "lists the articles in ascending published_at order" do
        articles = create_list(:article, 2, user: user)
        articles.first.update(published_at: 1.week.ago)
        articles.each { |a| a.update_columns(collection_id: collection.id) }

        visit articles.first.path

        elements = page.all(:xpath, articles_selector)
        paths = elements.pluck(:href)
        expect(paths).to eq([articles.first.path, articles.second.path])
      end
    end

    context "when a crossposted article is between two regular articles" do
      let(:article1) { create(:article, user: user) }
      let(:crossposted_article) { create(:article, user: user) }
      let(:article2) { create(:article, user: user) }

      it "lists the articles in ascending order considering crossposted_at" do
        article1.update_columns(
          collection_id: collection.id,
          published_at: Time.zone.parse("2020-03-15T13:50:09Z"),
        )

        crossposted_article.update_columns(
          canonical_url: Faker::Internet.url,
          collection_id: collection.id,
          crossposted_at: Time.zone.parse("2020-03-21T10:25:00Z"),
          feed_source_url: Faker::Internet.url,
          published_at: Time.zone.parse("2020-02-21T06:00:00Z"),
          published_from_feed: true,
        )

        article2.update_columns(collection_id: collection.id)

        visit article1.path

        expected_paths = [article1.path, crossposted_article.path, article2.path]

        elements = page.all(:xpath, articles_selector)
        paths = elements.pluck(:href)
        expect(paths).to eq(expected_paths)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe "when an article is scheduled" do
    let(:scheduled_article) { create(:article, user: user, published: true, published_at: Date.tomorrow) }
    let(:scheduled_article_path) { scheduled_article.path + query_params }
    let(:query_params) { "?preview=#{scheduled_article.password}" }

    it "shows the article edit link and hides the manage link for the author", :aggregate_failures, :js do
      visit scheduled_article_path
      edit_link = find("a#author-click-to-edit")
      expect(edit_link.matches_style?(display: "inline-block")).to be true
      expect(page).to have_no_link("article-action-space-manage")
    end

    it "hides the edit link from non-authorized and logged-out users", :aggregate_failures do
      expect_edit_link_hidden_from_non_authors(scheduled_article_path)
    end
  end

  describe "when an article is not published" do
    let(:article) { create(:article, user: article_user, published: false) }
    let(:article_path) { article.path + query_params }

    context "with the article password, and the logged-in user is authorized to update the article" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "shows the article edit link", :js do
        visit article_path
        edit_link = find("a#author-click-to-edit")
        expect(edit_link.matches_style?(display: "inline-block")).to be true
      end
    end

    context "with the article password, and the user is not the author" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "hides the edit link from non-authorized and logged-out users", :aggregate_failures do
        expect_edit_link_hidden_from_non_authors(article_path)
      end
    end

    # Requests without the preview password (author redirect, 404 for logged-out
    # and non-authorized users) are covered in spec/requests/stories_show_spec.rb.
  end
end
