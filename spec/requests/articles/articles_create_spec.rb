require "rails_helper"

RSpec.describe "ArticlesCreate", type: :request do
  let(:user) { create(:user, :org_member) }
  let(:template) { file_fixture("article_published.txt").read }
  let(:new_title) { "NEW TITLE #{rand(100)}" }

  before do
    sign_in user
  end

  it "creates ordinary article with proper params" do
    post "/articles", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(Article.last.user_id).to eq(user.id)
  end

  it "properly downcase tags" do
    post "/articles", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "What" }
    }
    expect(Article.last.tags.map(&:name)).to eq(["what"])
  end

  it "creates article with front matter params" do
    post "/articles", params: {
      article: {
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo"
      }
    }
    expect(Article.last.title).to eq("hey hey hahuu")
  end

  it "creates article with front matter params and org" do
    user_org_id = user.organizations.first.id
    post "/articles", params: {
      article: {
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo",
        organization_id: user_org_id
      }
    }
    expect(Article.last.organization_id).to eq(user_org_id)
  end

  it "creates series when series is created with frontmatter" do
    new_title = "NEW TITLE #{rand(100)}"
    post "/articles", params: {
      article: {
        title: new_title,
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\nseries: helloyo\n---\nYo ho ho#{rand(100)}"
      }
    }
    expect(Collection.last.slug).to eq("helloyo")
  end

  it "returns the ID and the current_state_path of the article" do
    post "/articles", params: { article: { body_markdown: template } }
    expect(response).to have_http_status(:ok)

    article = Article.last
    expect(response.parsed_body["id"]).to eq(article.id)
    expect(response.parsed_body["current_state_path"]).to eq(article.current_state_path)
  end

  context "when scheduling jobs" do
    let(:url) { Faker::Internet.url(scheme: "https") }
    let(:article_params) do
      {
        article: {
          title: "NEW TITLE #{rand(100)}",
          body_markdown: "---\ntitle: hey hey hahuu\npublished: false\nseries: helloyo\n---\nYo ho ho#{rand(100)}"
        }
      }
    end

    it "doesn't fail when executing jobs" do
      stub_request(:post, url).to_return(status: 200)
      sidekiq_perform_enqueued_jobs do
        post "/articles", params: article_params
      end
    end
  end

  context "when creation limit is reached" do
    it "returns a too_many_requests response if antispam rate limit is reached" do
      rate_limit_checker = RateLimitChecker.new(user)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action).and_return(true)

      post articles_path, params: { article: { body_markdown: "123" } }

      expect(response).to have_http_status(:too_many_requests)
      expected_retry_after = RateLimitChecker::ACTION_LIMITERS.dig(:published_article_antispam_creation, :retry_after)
      expect(response.headers["Retry-After"]).to eq(expected_retry_after)
    end

    it "returns a too_many_requests response if rate limit is reached" do
      # Explicitly create this user more than 3.days.ago, since we
      # check for this in Articles::Creator#rate_limit!
      user.update!(created_at: 4.days.ago)

      rate_limit_checker = RateLimitChecker.new(user)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action).and_return(true)

      post articles_path, params: { article: { body_markdown: "123 i love to spam" } }

      expect(response).to have_http_status(:too_many_requests)
      expected_retry_after = RateLimitChecker::ACTION_LIMITERS.dig(:published_article_creation, :retry_after)
      expect(response.headers["Retry-After"]).to eq(expected_retry_after)
    end
  end

  context "when setting published_at in editor v2" do
    let(:tomorrow) { 1.day.from_now }
    let(:attributes) do
      { title: new_title, body_markdown: "Yo ho ho#{rand(100)}",
        published: true,
        published_at_date: tomorrow.strftime("%Y-%m-%d"),
        published_at_time: "18:00" }
    end

    it "sets published_at according to the timezone new" do
      attributes[:timezone] = "Europe/Moscow"
      post "/articles", params: { article: attributes }
      a = Article.find_by(title: new_title)
      published_at_utc = a.published_at.in_time_zone("UTC").strftime("%m/%d/%Y %H:%M")
      expect(published_at_utc).to eq("#{tomorrow.strftime('%m/%d/%Y')} 15:00")
    end

    # crossing the date line
    it "sets published_at for another timezone new" do
      attributes[:timezone] = "Pacific/Honolulu"
      post "/articles", params: { article: attributes }
      a = Article.find_by(title: new_title)
      published_at_utc = a.published_at.in_time_zone("UTC").strftime("%m/%d/%Y %H:%M")
      expect(published_at_utc).to eq("#{(tomorrow + 1.day).strftime('%m/%d/%Y')} 04:00")
    end

    it "sets published_at when only date is passed" do
      attributes[:published_at_date] = 2.days.from_now.strftime("%Y-%m-%d")
      attributes[:published_at_time] = nil
      attributes[:timezone] = "Europe/Moscow"
      post "/articles", params: { article: attributes }
      a = Article.find_by(title: new_title)
      # 00:00 in user timezone (attributes[:timezone])
      published_at_utc = a.published_at.in_time_zone("UTC").strftime("%m/%d/%Y %H:%M")
      expect(published_at_utc).to eq("#{tomorrow.strftime('%m/%d/%Y')} 21:00")
    end

    it "sets current published_at when only time is passed" do
      attributes[:published_at_date] = nil
      attributes[:timezone] = "Asia/Magadan"
      post "/articles", params: { article: attributes }
      a = Article.find_by(title: new_title)
      expect(a.published_at).to be_within(1.minute).of(Time.current)
    end
  end

  context "when setting published_at from editor v1" do
    it "sets current published_at when publishing and published_at not specified" do
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      post "/articles", params: { article: { body_markdown: body_markdown } }
      a = Article.find_by(title: "super-article")
      expect(a.published_at).to be_within(1.minute).of(Time.current)
    end

    it "doesn't set published_at for drafts when published_at is not specified" do
      body_markdown = "---\ntitle: super-article\npublished: false\ndescription:\ntags: heytag
      \n---\n\nHey this is the article"
      post "/articles", params: { article: { body_markdown: body_markdown } }
      a = Article.find_by(title: "super-article")
      expect(a.published_at).to be_nil
    end

    it "sets published_at from frontmatter" do
      published_at = 10.days.from_now.in_time_zone("UTC")
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{published_at.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"
      post "/articles", params: { article: { body_markdown: body_markdown } }
      a = Article.find_by(title: "super-article")
      expect(a.published_at).to be_within(1.minute).of(published_at)
    end

    it "sets published_at with timezone from frontmatter" do
      published_at = 10.days.from_now.in_time_zone("America/Caracas")
      body_markdown = "---\ntitle: super-article\npublished: true\ndescription:\ntags: heytag
      \npublished_at: #{published_at.strftime('%Y-%m-%d %H:%M %z')}\n---\n\nHey this is the article"
      post "/articles", params: { article: { body_markdown: body_markdown } }
      a = Article.find_by(title: "super-article")
      # binding.pry
      expect(a.published_at).to be_within(1.minute).of(published_at)
    end
  end
end
