require "rails_helper"

RSpec.describe "ArticlesCreate", type: :request do
  let(:user) { create(:user, :org_member) }

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
      create(:webhook_endpoint, events: %w[article_created article_updated], target_url: url)
    end

    it "schedules a dispatching event job" do
      expect do
        post "/articles", params: article_params
      end.to have_enqueued_job(Webhook::DispatchEventJob).once
    end

    it "doesn't fail when executing jobs" do
      stub_request(:post, url).to_return(status: 200)
      perform_enqueued_jobs do
        post "/articles", params: article_params
      end
    end
  end
end
