require "rails_helper"

RSpec.describe "User profile comments" do
  let(:profile_owner) { create(:user) }
  let(:viewer) { create(:user) }
  let(:article) { create(:article, published: true, cached_tag_list: "ruby") }

  before do
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Visible comment one",
           deleted: false,
           score: 10)
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Visible comment two",
           deleted: false,
           score: 0)
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Deleted comment",
           deleted: true,
           score: 10)
    create(:comment,
           user: profile_owner,
           commentable: article,
           body_markdown: "Low quality comment",
           deleted: false,
           score: -100)
  end

  describe "GET /:username" do
    context "when visitor is signed in" do
      before do
        sign_in viewer
      end

      it "uses the same visible comment set for the sidebar count and comments section" do
        get "/#{profile_owner.username}"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
          .detect { |row| row.text.match?(/comments/i) }
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

    context "when visitor is not signed in" do
      it "displays the comments locked CTA and consistent sidebar count" do
        get "/#{profile_owner.username}"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
          .detect { |row| row.text.match?(/comments/i) }
        expect(sidebar_comment_row).to be_present

        sidebar_comment_count = sidebar_comment_row.text[/\d[\d,]*/]&.delete(",")&.to_i
        expect(sidebar_comment_count).to eq(2)
        expect(doc.css("#comments-locked-cta")).to be_present
      end
    end

    context "when user has zero comments" do
      let(:user_without_comments) { create(:user) }

      it "displays 0 comments in the sidebar and does not display the comments card" do
        sign_in viewer
        get "/#{user_without_comments.username}"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
          .detect { |row| row.text.match?(/comments/i) }
        expect(sidebar_comment_row).to be_present

        sidebar_comment_count = sidebar_comment_row.text[/\d[\d,]*/]&.delete(",")&.to_i
        expect(sidebar_comment_count).to eq(0)
        expect(doc.css("a.profile-comment-row")).to be_empty
        expect(doc.css("#comments-locked-cta")).not_to be_present
      end
    end

    context "when comments exist on unpublished articles" do
      let(:draft_article) { create(:article, published: true) }

      before do
        create(:comment,
               user: profile_owner,
               commentable: draft_article,
               body_markdown: "Draft article comment",
               deleted: false,
               score: 10)
        draft_article.update_columns(published: false)
        sign_in viewer
      end

      it "excludes comments on unpublished articles from sidebar count and comments section" do
        get "/#{profile_owner.username}"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
          .detect { |row| row.text.match?(/comments/i) }

        sidebar_comment_count = sidebar_comment_row.text[/\d[\d,]*/]&.delete(",")&.to_i
        expect(sidebar_comment_count).to eq(2)
        expect(doc.css("a.profile-comment-row").count).to eq(2)
        expect(response.body).not_to include("Draft article comment")
      end
    end

    context "when comments exist in another subforem" do
      let(:other_subforem) { create(:subforem) }
      let(:subforem_article) { create(:article, published: true, subforem_id: other_subforem.id) }

      before do
        create(:subforem)
        create(:comment,
               user: profile_owner,
               commentable: subforem_article,
               body_markdown: "Other subforem comment",
               deleted: false,
               score: 10)
        sign_in viewer
      end

      after do
        RequestStore.store[:subforem_id] = nil
        RequestStore.store[:default_subforem_id] = nil
        RequestStore.store[:root_subforem_id] = nil
      end

      it "excludes comments from different subforems" do
        get "/#{profile_owner.username}"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        sidebar_comment_row = doc.css("div.crayons-card--secondary.p-4 div.flex.items-center.mb-4")
          .detect { |row| row.text.match?(/comments/i) }

        sidebar_comment_count = sidebar_comment_row.text[/\d[\d,]*/]&.delete(",")&.to_i
        expect(sidebar_comment_count).to eq(2)
        expect(doc.css("a.profile-comment-row").count).to eq(2)
        expect(response.body).not_to include("Other subforem comment")
      end
    end
  end

  describe "GET /:username?view=comments" do
    context "when visitor is signed in" do
      before { sign_in viewer }

      it "renders the comments section and appropriate header" do
        get "/#{profile_owner.username}?view=comments"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        expect(doc.css("a.profile-comment-row").count).to eq(2)
        expect(doc.css("#comments-locked-cta")).not_to be_present
        expect(response.body).to include(I18n.t("views.users.comments.all.other"))
      end
    end

    context "when visitor is not signed in" do
      it "renders the locked CTA" do
        get "/#{profile_owner.username}?view=comments"
        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        expect(doc.css("#comments-locked-cta")).to be_present
        expect(doc.css("a.profile-comment-row")).to be_empty
      end
    end
  end
end
