# rubocop:disable RSpec/NestedGroups
require "rails_helper"

RSpec.describe "Partnerships", type: :request do
  describe "GET /partnerships" do
    context "when user is logged in" do
      before do
        get partnerships_path
      end

      it "renders main text" do
        expect(response.body).to include "Partner With"
      end
    end

    context "when user is not logged in" do
      before do
        user = create(:user)
        sign_in user
        get partnerships_path
      end

      it "renders main text" do
        expect(response.body).to include "Partner With"
      end
    end
  end

  describe "GET /partnerships/:show" do
    let(:user) { create(:user) }

    context "when user is logged in" do
      before do
        sign_in user
      end

      it "gets bronze sponsorship page" do
        get "/partnerships/bronze-sponsor"
        expect(response.body).to include("Bronze Sponsorship")
      end

      it "asks user to create org if not created" do
        get "/partnerships/bronze-sponsor"
        expect(response.body).to include("Create an Organization")
      end

      it "asks user to purchase credits if not purchased" do
        organization = create(:organization)
        OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "admin")
        get "/partnerships/bronze-sponsor"
        expect(response.body).to include("Purchase Credits")
      end

      it "includes sponsorship form if organization has credits" do
        organization = create(:organization)
        OrganizationMembership.create(user_id: user.id, organization_id: organization.id, type_of_user: "admin")
        Credit.add_to_org(organization, 100)
        get "/partnerships/bronze-sponsor"
        expect(response.body).to include("Subscribe for #{Sponsorship::CREDITS[:bronze]} credits")
      end

      context "when sponsorship exists" do
        let(:org) { create(:organization) }

        before do
          create(:organization_membership, user: user, organization: org, type_of_user: "admin")
          Credit.add_to_org(org, 1000)
          sign_in user
        end

        describe "level sponsorships" do
          it "displays info about an existing sponsorship" do
            create(:sponsorship, level: :bronze, organization: org, user: user, expires_at: 3.days.from_now)
            get "/partnerships/bronze-sponsor"
            expect(response.body).not_to include("Credits are your wallet for flexibly managing")
            expect(response.body).to include("You are Subscribed as a Bronze Sponsor")
          end

          it "displayes already sponsored for other level" do
            create(:sponsorship, level: :bronze, organization: org, user: user, expires_at: 3.days.from_now)
            get "/partnerships/silver-sponsor"
            expect(response.body).to include("You are already subscribed as a bronze sponsor")
          end

          it "doesn't display info about an expired sponsorship" do
            create(:sponsorship, level: :bronze, organization: org, user: user, expires_at: 3.days.ago)
            get "/partnerships/bronze-sponsor"
            expect(response.body).not_to include("You are Subscribed as a Bronze Sponsor")
          end

          it "doesn't display 'already sponsored' for the different level if an org has expired sponsorship" do
            create(:sponsorship, level: :bronze, organization: org, user: user, expires_at: 3.days.ago)
            get "/partnerships/silver-sponsor"
            expect(response.body).not_to include("You are already subscribed as a bronze sponsor")
          end
        end

        describe "tag sponsorships" do
          let(:ruby) { create(:tag, name: "ruby") }

          it "displays info about an existing sponsorship" do
            create(:sponsorship, level: :tag, organization: org, user: user, sponsorable: ruby, expires_at: 3.days.from_now)
            get "/partnerships/tag-sponsor"
            expect(response.body).to include("You are Subscribed as the sponsor of #ruby")
          end

          it "doesn't display info about an expired sponsorship" do
            create(:sponsorship, level: :tag, organization: org, user: user, sponsorable: ruby, expires_at: 3.days.ago)
            get "/partnerships/tag-sponsor"
            expect(response.body).not_to include("You are Subscribed as the sponsor of #ruby")
          end
        end
      end
    end

    context "when user is not logged in" do
      it "gets bronze sponsorship page" do
        get "/partnerships/bronze-sponsor"
        expect(response.body).to include("Bronze Sponsorship")
        expect(response.body).to include("Sign in to get started")
      end
    end
  end

  describe "POST /partnerships" do
    let(:user) { create(:user) }
    let(:org) { create(:organization) }

    context "when user is logged in as an admin and has enough credits" do
      before do
        create(:organization_membership, user: user, organization: org, type_of_user: "admin")
        sign_in user
      end

      # context "when purchasing a gold sponsorship" is skipped due
      # to the high amount of required credits

      context "when purchasing a silver sponsorship" do
        let(:params) { { level: :silver, organization_id: org.id } }

        before do
          Credit.add_to_org(org, Sponsorship::CREDITS[:silver])
        end

        it "creates a new sponsorship" do
          expect do
            post partnerships_path, params: params
            expect(response).to redirect_to(partnerships_path)
          end.to change(org.sponsorships, :count).by(1)
        end

        it "subscribes with the correct info" do
          Timecop.freeze(Time.current) do
            post partnerships_path, params: params
            sponsorship = org.sponsorships.silver.last
            expect(sponsorship.status).to eq("pending")
            expect(sponsorship.expires_at.to_i).to eq(1.month.from_now.to_i)
            expect(sponsorship.sponsorable).to be(nil)
            expect(sponsorship.instructions).to be_blank
            expect(sponsorship.instructions_updated_at).to be(nil)
          end
        end

        it "detracts the correct amount of credits" do
          expect do
            post partnerships_path, params: params
          end.to change(org.credits.spent, :size).by(Sponsorship::CREDITS[:silver])
          credit = org.credits.spent.last
          expect(credit.purchase.is_a?(Sponsorship)).to be(true)
        end

        it "queues a slack message to be sent" do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            post partnerships_path, params: params
          end
        end
      end

      context "when purchasing a bronze sponsorship" do
        let(:params) { { level: :bronze, organization_id: org.id } }

        before do
          Credit.add_to_org(org, Sponsorship::CREDITS[:bronze])
        end

        it "creates a new sponsorship" do
          expect do
            post partnerships_path, params: params
            expect(response).to redirect_to(partnerships_path)
          end.to change(org.sponsorships, :count).by(1)
        end

        it "subscribes with the correct info" do
          Timecop.freeze(Time.current) do
            post partnerships_path, params: params
            sponsorship = org.sponsorships.bronze.last
            expect(sponsorship.status).to eq("pending")
            expect(sponsorship.expires_at.to_i).to eq(1.month.from_now.to_i)
            expect(sponsorship.sponsorable).to be(nil)
            expect(sponsorship.instructions).to be_blank
            expect(sponsorship.instructions_updated_at).to be(nil)
          end
        end

        it "detracts the correct amount of credits" do
          expect do
            post partnerships_path, params: params
          end.to change(org.credits.spent, :size).by(Sponsorship::CREDITS[:bronze])
          credit = org.credits.spent.last
          expect(credit.purchase.is_a?(Sponsorship)).to be(true)
        end

        it "queues a slack message to be sent" do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            post partnerships_path, params: params
          end
        end
      end

      context "when purchasing a devrel sponsorship" do
        let(:params) { { level: :devrel, organization_id: org.id } }

        before do
          Credit.add_to_org(org, Sponsorship::CREDITS[:devrel])
        end

        it "creates a new sponsorship" do
          expect do
            post partnerships_path, params: params
            expect(response).to redirect_to(partnerships_path)
          end.to change(org.sponsorships, :count).by(1)
        end

        it "subscribes with the correct info" do
          Timecop.freeze(Time.current) do
            post partnerships_path, params: params
            sponsorship = org.sponsorships.devrel.last
            expect(sponsorship.status).to eq("pending")
            expect(sponsorship.expires_at).to be(nil)
            expect(sponsorship.sponsorable).to be(nil)
            expect(sponsorship.instructions).to be_blank
            expect(sponsorship.instructions_updated_at).to be(nil)
          end
        end

        it "detracts the correct amount of credits" do
          expect do
            post partnerships_path, params: params
          end.to change(org.credits.spent, :size).by(Sponsorship::CREDITS[:devrel])
          credit = org.credits.spent.last
          expect(credit.purchase.is_a?(Sponsorship)).to be(true)
        end

        it "queues a slack message to be sent" do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            post partnerships_path, params: params
          end
        end
      end

      context "when purchasing a media sponsorship" do
        let(:params) do
          { level: :media, organization_id: org.id, amount: 10 }
        end

        before do
          Credit.add_to_org(org, params[:amount])
        end

        it "creates a new sponsorship" do
          expect do
            post partnerships_path, params: params
            expect(response).to redirect_to(partnerships_path)
          end.to change(org.sponsorships, :count).by(1)
        end

        it "subscribes with the correct info" do
          Timecop.freeze(Time.current) do
            post partnerships_path, params: params
            sponsorship = org.sponsorships.media.last
            expect(sponsorship.status).to eq("pending")
            expect(sponsorship.expires_at).to be(nil)
            expect(sponsorship.sponsorable).to be(nil)
            expect(sponsorship.instructions).to be_blank
            expect(sponsorship.instructions_updated_at).to be(nil)
          end
        end

        it "detracts the correct amount of credits" do
          expect do
            post partnerships_path, params: params
          end.to change(org.credits.spent, :size).by(params[:amount])
          credit = org.credits.spent.last
          expect(credit.purchase.is_a?(Sponsorship)).to be(true)
        end

        it "queues a slack message to be sent" do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            post partnerships_path, params: params
          end
        end
      end

      context "when purchasing a tag sponsorship" do
        let(:tag) { create(:tag) }
        let(:params) { { level: :tag, organization_id: org.id, tag_name: tag.name } }

        before do
          Credit.add_to_org(org, Sponsorship::CREDITS[:tag])
        end

        it "creates a new sponsorship" do
          expect do
            post partnerships_path, params: params
            expect(response).to redirect_to(partnerships_path)
          end.to change(org.sponsorships, :count).by(1)
        end

        it "subscribes with the correct info" do
          Timecop.freeze(Time.current) do
            post partnerships_path, params: params
            sponsorship = org.sponsorships.tag.last
            expect(sponsorship.status).to eq("pending")
            expect(sponsorship.expires_at.to_i).to eq(1.month.from_now.to_i)
            expect(sponsorship.sponsorable).not_to be(nil)
            expect(sponsorship.instructions).to be_blank
            expect(sponsorship.instructions_updated_at).to be(nil)
          end
        end

        it "detracts the correct amount of credits" do
          expect do
            post partnerships_path, params: params
          end.to change(org.credits.spent, :size).by(Sponsorship::CREDITS[:tag])
          credit = org.credits.spent.last
          expect(credit.purchase.is_a?(Sponsorship)).to be(true)
        end

        it "queues a slack message to be sent" do
          sidekiq_assert_enqueued_with(job: SlackBotPingWorker) do
            post partnerships_path, params: params
          end
        end
      end

      it "updates sponsorship instructions if present" do
        Credit.add_to_org(org, Sponsorship::CREDITS[:bronze])

        post partnerships_path, params: {
          level: :bronze,
          organization_id: org.id,
          instructions: "hello there"
        }
        sponsorship = org.sponsorships.bronze.last
        expect(sponsorship.instructions).to include("hello there")
        expect(sponsorship.instructions_updated_at).not_to be(nil)
      end
    end

    context "when user is logged in as a non organization admin but has enough credits" do
      before do
        create(:organization_membership, user: user, organization: org, type_of_user: "member")
        Credit.add_to_org(org, Sponsorship::CREDITS[:bronze])
        sign_in user
      end

      it "does not subscribe to a bronze sponsorship" do
        expect do
          post partnerships_path, params: {
            level: "bronze",
            organization_id: org.id
          }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
# rubocop:enable RSpec/NestedGroups
