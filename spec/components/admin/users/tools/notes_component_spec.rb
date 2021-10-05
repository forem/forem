require "rails_helper"

RSpec.describe Admin::Users::Tools::NotesComponent, type: :component do
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

  describe "Create note" do
    it "renders the section", :aggregate_failures do
      render_inline(described_class.new(user: user))

      selector = "form[action='#{admin_user_tools_notes_path(user)}'][method='post'][data-remote='true']"
      expect(rendered_component).to have_css(selector)
    end
  end

  describe "Notes history" do
    it "does not render the section by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_text("Recent Notes")
    end

    it "renders the section if the user has notes", :aggregate_failures do
      note = create(:note, noteable: user, author: create(:user))
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("Recent Notes")
      expect(rendered_component).to have_text(note.created_at.strftime("%d %B %Y %H:%M %Z"))
      expect(rendered_component).to have_text(note.author.username)
      expect(rendered_component).to have_text(note.reason)
      expect(rendered_component).to have_text(note.content)
    end
  end
end
