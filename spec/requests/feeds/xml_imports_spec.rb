require "rails_helper"

RSpec.describe "Feeds::XmlImports" do
  let(:user) { create(:user) }

  describe "POST /feeds/xml_imports" do
    context "when not signed in" do
      it "redirects to sign in" do
        post feeds_xml_imports_path, params: { xml_content: "<rss/>" }
        expect(response).to redirect_to("/enter")
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "redirects to feed imports dashboard on success" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ imported: 2 })

        post feeds_xml_imports_path, params: { xml_content: "<rss/>" }

        expect(response).to redirect_to(dashboard_feed_imports_path)
      end

      it "shows success flash with import count" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ imported: 3 })

        post feeds_xml_imports_path, params: { xml_content: "<rss/>" }

        follow_redirect!
        expect(flash[:notice]).to include("3")
      end

      it "shows error flash when import fails" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ error: "Could not parse XML" })

        post feeds_xml_imports_path, params: { xml_content: "not xml" }

        follow_redirect!
        expect(flash[:error]).to eq("Could not parse XML")
      end

      it "passes xml_content and current user to service" do
        allow(Feeds::ImportFromXml).to receive(:call).and_return({ imported: 0 })

        post feeds_xml_imports_path, params: { xml_content: "<rss/>" }

        expect(Feeds::ImportFromXml).to have_received(:call).with(
          xml_content: "<rss/>",
          user: user,
        )
      end
    end
  end
end
