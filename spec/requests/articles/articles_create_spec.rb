require "rails_helper"

RSpec.describe "ArticlesCreate", type: :request do
  let(:user) { create(:user, :org_member) }
  let(:template) { file_fixture("article_published.txt").read }

  before do
    sign_in user
  end

  it "creates ordinary article with proper params" do
    new_title = "NEW TITLE #{rand(100)}"
    post "/articles", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(Article.last.user_id).to eq(user.id)
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

    before do
      create(:webhook_endpoint, events: %w[article_created article_updated], target_url: url, user: user)
    end

    it "doesn't schedule a dispatching event job (unpublished)" do
      sidekiq_assert_no_enqueued_jobs(only: Webhook::DispatchEventWorker) do
        post "/articles", params: article_params
      end
    end

    it "schedules a dispatching event job (published)" do
      article_params[:article][:body_markdown] = "---\ntitle: hey hey hahuu\npublished: true\nseries: helloyo\n---\nYo ho ho#{rand(100)}"
      sidekiq_assert_enqueued_jobs(1, only: Webhook::DispatchEventWorker) do
        post "/articles", params: article_params
      end
    end

    it "doesn't fail when executing jobs" do
      stub_request(:post, url).to_return(status: 200)
      sidekiq_perform_enqueued_jobs do
        post "/articles", params: article_params
      end
    end
  end
end
