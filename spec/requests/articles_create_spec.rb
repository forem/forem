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
end
