require "rails_helper"

RSpec.describe Admin::Users::Tools::EmailsComponent, type: :component do
  let(:user) { create(:user) }

  describe "Verification" do
    it "renders the section", :aggregate_failures do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("To: #{user.name}")
      expect(rendered_component).to have_text(user.email)
      expect(rendered_component).not_to have_text("Verified on")
      expect(rendered_component).to have_css('form[data-users--tools--emails-target="verifyEmailOwnership"]')
    end

    it "renders the section with verification info" do
      allow(user).to receive(:last_verification_date).and_return(1.day.ago)
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("Verified on")
    end
  end

  describe "Send Email" do
    it "renders the section" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_css('form[data-users--tools--emails-target="sendEmail"]')
    end
  end

  describe "Email history" do
    it "does not render the section by default" do
      render_inline(described_class.new(user: user))

      expect(rendered_component).not_to have_text("Emails history")
    end

    it "renders the section if the user has email messages", :aggregate_failures do
      email = create(:email_message, user: user)
      render_inline(described_class.new(user: user))

      expect(rendered_component).to have_text("Emails history")
      expect(rendered_component).to have_link(href: admin_user_email_message_path(user, email), visible: :hidden)
    end
  end
end
