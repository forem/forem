require "rails_helper"

RSpec.describe Feeds::XmlImportsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:valid_xml) { "<rss><channel><item><title>A</title></item></channel></rss>" }

  describe "POST #create" do
    context "when not signed in" do
      it "redirects to sign in" do
        post :create, params: { xml_content: valid_xml }
        expect(response).to redirect_to("/magic_links/new")
      end
    end

    context "when user is suspended" do
      before do
        user.add_role(:suspended)
        sign_in user
      end

      it "raises Pundit::NotAuthorizedError" do
        expect do
          post :create, params: { xml_content: valid_xml }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user lacks article creation permission" do
      before do
        allow(ArticlePolicy).to receive(:limit_post_creation_to_admins?).and_return(true)
        sign_in user
      end

      it "raises Pundit::NotAuthorizedError" do
        expect do
          post :create, params: { xml_content: valid_xml }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when signed in and authorized" do
      before { sign_in user }

      it "calls ImportFromXml service and redirects to dashboard" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ imported: 1 })

        post :create, params: { xml_content: valid_xml }

        expect(response).to redirect_to(dashboard_feed_imports_path)
        expect(flash[:notice]).to be_present
      end

      it "sets warning flash when zero items are imported" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ imported: 0 })

        post :create, params: { xml_content: valid_xml }

        expect(flash[:warning]).to eq(I18n.t("feeds.xml_imports.none_imported"))
      end
    end
  end
end
