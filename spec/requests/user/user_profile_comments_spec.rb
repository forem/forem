require "rails_helper"

RSpec.describe "User profile comments", type: :request do
  let(:profile_owner) { create(:user) }
  let(:viewer) { create(:user) }
  let(:article) { create(:article, published: true, cached_tag_list: "ruby") }

  let!(:visible_comment_one) do
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Visible comment one",
           deleted: false,
           score: 10)
  end

  let!(:visible_comment_two) do
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Visible comment two",
           deleted: false,
           score: 0)
  end

  let!(:deleted_comment) do
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Deleted comment",
           deleted: true,
           score: 10)
  end

  let!(:low_quality_comment) do
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Low quality comment",
           deleted: false,
           score: -100)
  end

  before do
    sign_in viewer
  end

  describe "GET /:username" do
    it "uses the same visible comment set for the sidebar count and comments section" do
      get "/#{profile_owner.username}"
      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
                               .find { |row| row.text.match?(/comments/i) }
      expect(sidebar_comment_row).to be_present

      sidebar_comment_count = sidebar_comment_row.text[/\d[\d,]*/]&.delete(",")&.to_i
      expect(sidebar_comment_count).to eq(2)
      expect(doc.css("a.profile-comment-row").count).to eq(2)

      expect(response.body).to include("Visible comment one")
      expect(response.body).to include("Visible comment two")
      expect(response.body).not_to include("Deleted comment")
      expect(response.body).not_to include("Low quality comment")
    end
  end
end