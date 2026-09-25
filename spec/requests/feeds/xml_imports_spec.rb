require "rails_helper"

RSpec.describe "Feeds::XmlImports" do
  let(:user) { create(:user) }

  let(:valid_rss) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Blog</title>
          <link>https://example.com</link>
          <description>Test blog description</description>
          <item>
            <title>My First Post</title>
            <link>https://example.com/posts/first-post</link>
            <description><![CDATA[<p>Hello world post content</p>]]></description>
            <pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
          </item>
        </channel>
      </rss>
    XML
  end

  describe "GET /dashboard/feed_imports" do
    context "when signed in" do
      before { sign_in user }

      it "renders the XML content textarea with an accessible label" do
        get dashboard_feed_imports_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/<label[^>]*for="xml_content"/)
        expect(response.body).to include(I18n.t("views.dashboard.feed_imports.xml_import.textarea_label"))
      end
    end
  end

  describe "POST /feeds/xml_imports" do
    context "when not signed in" do
      it "redirects to sign in" do
        post feeds_xml_imports_path, params: { xml_content: valid_rss }
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when user is suspended" do
      before do
        user.add_role(:suspended)
        sign_in user
      end

      it "raises Pundit::NotAuthorizedError and denies import" do
        expect do
          post feeds_xml_imports_path, params: { xml_content: valid_rss }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user lacks article creation permission" do
      before do
        allow(ArticlePolicy).to receive(:limit_post_creation_to_admins?).and_return(true)
        sign_in user
      end

      it "raises Pundit::NotAuthorizedError and denies import" do
        expect do
          post feeds_xml_imports_path, params: { xml_content: valid_rss }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when signed in and authorized" do
      before { sign_in user }

      it "imports articles, sets notice flash, and redirects to dashboard" do
        expect do
          post feeds_xml_imports_path, params: { xml_content: valid_rss }
        end.to change(user.articles, :count).by(1)

        expect(response).to redirect_to(dashboard_feed_imports_path)
        follow_redirect!
        expect(flash[:notice]).to eq(I18n.t("feeds.xml_imports.success", count: 1))
      end

      it "shows warning flash when all items are duplicates (0 imported)" do
        # First import
        post feeds_xml_imports_path, params: { xml_content: valid_rss }
        expect(user.articles.count).to eq(1)

        # Second import with identical items
        expect do
          post feeds_xml_imports_path, params: { xml_content: valid_rss }
        end.not_to change(user.articles, :count)

        expect(response).to redirect_to(dashboard_feed_imports_path)
        follow_redirect!
        expect(flash[:warning]).to eq(I18n.t("feeds.xml_imports.none_imported"))
        expect(flash[:notice]).to be_nil
        expect(response.body).to include("crayons-notice crayons-notice--warning")
        expect(response.body).to include(I18n.t("feeds.xml_imports.none_imported"))
      end

      it "shows error flash when XML is invalid" do
        post feeds_xml_imports_path, params: { xml_content: "not-xml-at-all" }

        expect(response).to redirect_to(dashboard_feed_imports_path)
        follow_redirect!
        expect(flash[:error]).to eq(I18n.t("feeds.xml_imports.invalid_xml"))
      end

      it "shows error flash when XML content is blank" do
        post feeds_xml_imports_path, params: { xml_content: "" }

        expect(response).to redirect_to(dashboard_feed_imports_path)
        follow_redirect!
        expect(flash[:error]).to eq(I18n.t("feeds.xml_imports.blank"))
      end
    end
  end
end
