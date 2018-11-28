require "rails_helper"

RSpec.describe "ArticlesCreate", type: :request do
  let(:user) { create(:user) }

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

  # rubocop:disable RSpec/ExampleLength
  it "creates article with front matter params" do
    post "/articles", params: {
      article: {
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo"
      }
    }
    expect(Article.last.title).to eq("hey hey hahuu")
  end

  it "does not allow job opportunity job to not include hiring tag" do
    new_title = "NEW TITLE #{rand(100)}"
    expect do
      post "/articles", params: {
        article: {
          title: new_title,
          body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yoyo",
          job_opportunity: { remoteness: "on_premise" }
        }
      }
    end .to raise_error(RuntimeError)
  end

  it "creates article with job opportunity nested" do
    new_title = "NEW TITLE #{rand(100)}"
    post "/articles", params: {
      article: {
        title: new_title,
        body_markdown: "Yo ho ho#{rand(100)}", tag_list: "hiring",
        job_opportunity: { remoteness: "on_premise" }
      }
    }
    expect(Article.last.job_opportunity.remoteness).to eq("on_premise")
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
  # rubocop:enable RSpec/ExampleLength
end
