require "rails_helper"

RSpec.describe Admin::Users::ToolsComponent, type: :component do
  let(:user) { create(:user) }

  describe "Emails" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Emails")
    end

    it "renders the emails count" do
      create(:email_message, user: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("1 past email")
    end

    it "does not render the Verified text by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_text("Verified")
    end

    it "render the Verified text when verified is true" do
      allow(EmailAuthorization).to receive(:last_verification_date).with(user).and_return(Time.current)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("Verified")
    end
  end

  describe "Notes" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Notes")
    end

    it "renders the notes count" do
      create(:note, noteable: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("1 note")
    end
  end

  describe "Credits" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Credits")
    end

    it "renders the credits count" do
      Credit.add_to(user, 1)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("1 credit")
    end
  end

  describe "Organizations" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Organizations")
    end

    it "renders the credits count" do
      create(:organization_membership, user: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("1 organization")
    end
  end

  describe "Reports" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Reports")
    end

    it "renders the credits count" do
      create(:feedback_message, reporter: user)

      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("1 report")
    end
  end

  describe "Reactions" do
    it "renders the header" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css("h4", text: "Reactions")
    end

    it "renders the credits count" do
      moderator = create(:user, :trusted)
      create(:vomit_reaction, user: moderator, reactable: user)

      render_inline(described_class.new(user: moderator))

      expect(rendered_component).to have_text("1 reaction")
    end
  end
end
