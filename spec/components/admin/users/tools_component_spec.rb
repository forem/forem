require "rails_helper"

RSpec.describe Admin::Users::ToolsComponent, type: :component do
  describe "Emails" do
    it "renders the header" do
      render_inline(described_class.new(emails: { foo: :bar }))

      expect(rendered_component).to have_css("h4", text: "Emails")
    end

    it "renders the emails count" do
      render_inline(described_class.new(emails: { count: 3 }))

      expect(rendered_component).to have_text("3 past emails")
    end

    it "does not render the Verified text by default" do
      render_inline(described_class.new(emails: { count: 3 }))

      expect(rendered_component).not_to have_text("Verified")
    end

    it "render the Verified text when verified is true" do
      render_inline(described_class.new(emails: { count: 3, verified: true }))

      expect(rendered_component).to have_text("Verified")
    end
  end
end
