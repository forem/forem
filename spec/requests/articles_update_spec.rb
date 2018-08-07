require "rails_helper"

RSpec.describe "ArticlesUpdate", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  it "updates ordinary article with proper params" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" },
    }
    expect(Article.last.title).to eq(new_title)
  end

  # rubocop:disable RSpec/ExampleLength
  it "does not create a job opportunity if no hiring tag" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: {
        title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo",
        job_opportunity: { remoteness: "on_premise" }
      },
    }
    expect(JobOpportunity.count).to eq(0)
  end

  it "updates ordinary article with job opportunity nested" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: {
        title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "hiring",
        job_opportunity: { remoteness: "on_premise" }
      },
    }
    expect(Article.last.job_opportunity.remoteness).to eq("on_premise")
  end
  # rubocop:enable RSpec/ExampleLength
end
