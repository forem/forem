require "rails_helper"

RSpec.describe ProMembershipMailer, type: :mailer do
  let(:pro_membership) { build_stubbed(:pro_membership) }
  let(:user) { pro_membership.user }

  describe "#expiring_membership" do
    it "works correctly" do
      Timecop.freeze(Time.current) do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)

        expect(email.subject).to eq("Your Pro Membership will expire in 7 days!")
        expect(email.to).to eq([user.email])
        expect(email.from).to eq([SiteConfig.default_site_email])
        expect(email["from"].value).to eq("DEV Pro Memberships <#{SiteConfig.default_site_email}>")
      end
    end

    context "when generating the plain text email" do
      it "includes the user's name" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.text_part.body).to include(user.name)
      end

      it "includes the expiration date" do
        Timecop.freeze(Time.current) do
          expiration_date = 1.week.from_now
          email = described_class.expiring_membership(pro_membership, expiration_date)
          expect(email.text_part.body).to include(expiration_date.to_date.to_s(:long))
        end
      end

      it "includes credits path" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.text_part.body).to include(credits_path)
      end

      it "includes pro membership path" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.text_part.body).to include(user_settings_path("pro-membership"))
      end
    end

    context "when generating the html email" do
      it "includes the user's name" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.html_part.body).to include(user.name)
      end

      it "includes the expiration date" do
        Timecop.freeze(Time.current) do
          expiration_date = 1.week.from_now
          email = described_class.expiring_membership(pro_membership, expiration_date)
          expect(email.html_part.body).to include(expiration_date.to_date.to_s(:long))
        end
      end

      it "includes credits path" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.html_part.body).to include(CGI.escape(credits_path))
      end

      it "includes pro membership path" do
        email = described_class.expiring_membership(pro_membership, 1.week.from_now)
        expect(email.html_part.body).to include(CGI.escape(user_settings_path("pro-membership")))
      end
    end
  end
end
