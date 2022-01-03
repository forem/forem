require "rails_helper"

RSpec.describe Admin::Users::Tools::ReactionsComponent, type: :component do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :trusted) }

  it "renders the header", :aggregate_failures do
    render_inline(described_class.new(user: user))

    expect(rendered_component).to have_css("h3", text: "← Tools")
    expect(rendered_component).to have_link(href: admin_user_tools_path(user))
  end

  it "renders the section title for the screen reader", :aggregate_failures do
    render_inline(described_class.new(user: user))

    expect(rendered_component).to have_css("div", id: "section-title", class: "hidden")
  end

  describe "View reactions" do
    it "does not render the section by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_css("article")
    end

    it "renders the section if the user receives a vomit on one of their articles", :aggregate_failures do
      article = create(:article, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: article)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(reaction.category.capitalize)
      expect(rendered_component).to have_text(reaction.reactable_type)
      expect(rendered_component).to have_text(reaction.reactable.title)
    end

    it "renders the section if the user receives a vomit on one of their comments", :aggregate_failures do
      comment = create(:comment, user: user)
      reaction = create(:vomit_reaction, user: moderator, reactable: comment)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text(reaction.category.capitalize)
      expect(rendered_component).to have_text(reaction.reactable_type)
      expect(rendered_component).to have_text(reaction.reactable.title)
    end

    it "renders the section if the user left vomit reactions", :aggregate_failures do
      reaction = create(:vomit_reaction, user: moderator, reactable: user)

      render_inline(described_class.new(user: moderator))

      expect(rendered_component).to have_text(reaction.category.capitalize)
      expect(rendered_component).to have_text(reaction.reactable_type)
    end
  end
end
