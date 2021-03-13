require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let(:user) { create(:user) }
  let(:article) do
    create(:article, :with_notification_subscription, user: user)
  end

  before do
    sign_in user
  end

  it "shows an article", js: true do
    visit article.path
    expect(page).to have_content(article.title)
  end

  it "shows comments", js: true do
    create_list(:comment, 3, commentable: article)

    visit article.path
    expect(page).to have_selector(".single-comment-node", visible: :visible, count: 3)
  end

  it "stops a user from moderating an article" do
    expect { visit("/#{user.username}/#{article.slug}/mod") }.to raise_error(Pundit::NotAuthorizedError)
  end

  describe "sticky nav sidebar" do
    it "suggests articles by other users if the author has no other articles" do
      create(:article, user: create(:user))
      visit article.path
      expect(page).to have_text("Trending on #{SiteConfig.community_name}")
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
    it "shows the readable publish date" do
      visit article.path
      expect(page).to have_selector("article time", text: article.readable_publish_date.gsub("  ", " "))
    end

    it "embeds the published timestamp" do
      visit article.path

      selector = "article time[datetime='#{article.decorate.published_timestamp}']"
      expect(page).to have_selector(selector)
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
        expect(page).to have_selector("article time", text: first_article.readable_publish_date.gsub("  ", " "))
        expect(page).to have_selector(".crayons-card--secondary time",
                                      text: first_article.readable_publish_date.gsub("  ", " "))
        visit second_article.path
        expect(page).to have_selector("article time", text: second_article.readable_publish_date.gsub("  ", " "))
        expect(page).to have_selector(".crayons-card--secondary time",
                                      text: second_article.readable_publish_date.gsub("  ", " "))
      end
    end
  end

  describe "when articles belong to a collection" do
    let(:collection) { create(:collection) }
    let(:articles_selector) { "//div[@class='series-switcher__list']//a" }

    context "with regular articles" do
      it "lists the articles in ascending published_at order" do
        articles = create_list(:article, 2)
        articles.first.update(published_at: 1.week.ago)
        articles.each { |a| a.update_columns(collection_id: collection.id) }

        visit articles.first.path

        elements = page.all(:xpath, articles_selector)
        paths = elements.pluck(:href)
        expect(paths).to eq([articles.first.path, articles.second.path])
      end
    end

    context "when a crossposted article is between two regular articles" do
      let(:article1) { create(:article) }
      let(:crossposted_article) { create(:article) }
      let(:article2) { create(:article) }

      # rubocop:disable RSpec/ExampleLength
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

  describe "when an article is not published" do
    let(:article) { create(:article, user: article_user, published: false) }
    let(:article_path) { article.path + query_params }

    context "with the article password, and the logged-in user is authorized to update the article" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "shows the article edit link", js: true do
        visit article_path
        edit_link = find("a#author-click-to-edit")
        expect(edit_link.matches_style?(display: "inline-block")).to be true
      end
    end

    context "with the article password, and the logged-in user is not authorized to update the article" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { create(:user) }

      it "does not the article edit link" do
        visit article_path
        expect(page.body).not_to include('display: inline-block;">Click to edit</a>')
      end
    end

    context "with the article password, and the user is not logged-in" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "does not the article edit link" do
        sign_out user
        visit article_path
        expect(page.body).not_to include('display: inline-block;">Click to edit</a>')
      end
    end

    context "without the article password" do
      let(:query_params) { "" }
      let(:article_user) { user }

      it "raises ActiveRecord::RecordNotFound" do
        expect { visit article_path }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
