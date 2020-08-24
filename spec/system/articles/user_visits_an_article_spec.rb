require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let(:user) { create(:user) }
  let(:article) do
    create(:article, :with_notification_subscription, user: user)
  end
  let(:timestamp) { "2019-03-04T10:00:00Z" }

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

  describe "when showing the date" do
    before do
      article.update_columns(published_at: Time.zone.parse(timestamp))
    end

    it "shows the readable publish date", js: true do
      visit article.path
      expect(page).to have_selector("article time", text: "Mar 4")
    end

    it "embeds the published timestamp" do
      visit article.path
      selector = "article time[datetime='#{timestamp}']"
      expect(page).to have_selector(selector)
    end

    context "when articles have long markdowns and different published dates" do
      let(:first_article) { build(:article, published_at: "2019-03-04T10:00:00Z") }
      let(:second_article) { build(:article, published_at: "2019-03-05T10:00:00Z") }

      before do
        [first_article, second_article].each do |article|
          additional_characters_length = (ArticleDecorator::LONG_MARKDOWN_THRESHOLD + 1) - article.body_markdown.length
          article.body_markdown << Faker::Hipster.paragraph_by_chars(characters: additional_characters_length)
          article.save!
        end
      end

      it "shows the identical readable publish dates in each page", js: true do
        visit first_article.path
        expect(page).to have_selector("article time", text: "Mar 4")
        expect(page).to have_selector(".crayons-card--secondary time", text: "Mar 4")
        visit second_article.path
        expect(page).to have_selector("article time", text: "Mar 5")
        expect(page).to have_selector(".crayons-card--secondary time", text: "Mar 5")
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
    let(:href) { "#{article.path}/edit" }
    let(:link_text) { "Click to edit" }

    context "with the article password, and the logged-in user is authorized to update the article" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "shows the article edit link" do
        visit article_path
        expect(page).to have_link(link_text, href: href)
      end
    end

    context "with the article password, and the logged-in user is not authorized to update the article" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { create(:user) }

      it "does not the article edit link" do
        visit article_path
        expect(page).not_to have_link(link_text, href: href)
      end
    end

    context "with the article password, and the user is not logged-in" do
      let(:query_params) { "?preview=#{article.password}" }
      let(:article_user) { user }

      it "does not the article edit link" do
        sign_out user
        visit article_path
        expect(page).not_to have_link(link_text, href: href)
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
