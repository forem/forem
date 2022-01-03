require "rails_helper"

RSpec.describe Admin::Users::Tools::ReportsComponent, type: :component do
  let(:user) { create(:user) }

  it "renders the header", :aggregate_failures do
    render_inline(described_class.new(user: user))

    expect(rendered_component).to have_css("h3", text: "← Tools")
    expect(rendered_component).to have_link(href: admin_user_tools_path(user))
  end

  it "renders the section title for the screen reader", :aggregate_failures do
    render_inline(described_class.new(user: user))

    expect(rendered_component).to have_css("div", id: "section-title", class: "hidden")
  end

  describe "View reports" do
    it "does not render the section by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_css("article")
    end

    it "renders the section if the user leaves a report", :aggregate_failures do
      report = create(:feedback_message, reporter: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(report.category.capitalize)
      expect(rendered_component).to have_text(report.status)
      expect(rendered_component).to have_text(report.message)
    end

    it "renders the section if the user is affected by a report", :aggregate_failures do
      report = create(:feedback_message, affected: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(report.category.capitalize)
      expect(rendered_component).to have_text(report.status)
      expect(rendered_component).to have_text(report.message)
    end

    it "renders the section if the user is reported", :aggregate_failures do
      report = create(:feedback_message, offender: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(report.category.capitalize)
      expect(rendered_component).to have_text(report.status)
      expect(rendered_component).to have_text(report.message)
    end
  end
end
