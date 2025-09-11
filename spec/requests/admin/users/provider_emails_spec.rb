require "rails_helper"

RSpec.describe "Admin User Provider Emails" do
  let(:admin) { create(:user, :super_admin) }
  let(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe "GET /admin/member_manager/users/:id" do
    context "when viewing the emails tab" do
      before do
        get "#{admin_user_path(user)}?tab=emails"
      end

      it "displays the primary email" do
        expect(response.body).to include(user.email)
        expect(response.body).to include(I18n.t("views.settings.account.primary"))
      end

      context "when user has provider emails" do
        let(:user) do
          omniauth_mock_github_payload
          create(:user, :with_identity, identities: ["github"])
        end

        it "displays provider emails" do
          expect(response.body).to include(user.identities.first.email)
          expect(response.body).to include(I18n.t("views.settings.account.provider_email", 
            provider: Authentication::Providers.get!("github").official_name))
        end
      end

      context "when user has no provider emails" do
        it "only displays primary email" do
          expect(response.body).to include(user.email)
          expect(response.body).not_to include(I18n.t("views.settings.account.provider_email", 
            provider: Authentication::Providers.get!("github").official_name))
        end
      end
    end
  end
end 