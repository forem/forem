require "rails_helper"

RSpec.describe "Credits", type: :request do
  describe "GET /credits" do
    let(:user) { create(:user) }
    let(:org_member) { create(:user, :org_member) }
    let(:org_admin) { create(:user, :org_admin) }

    it "shows credits page" do
      sign_in user
      get "/credits"
      expect(response.body).to include("You have")
    end

    it "shows credits page if user belongs to an org" do
      org = org_member.organizations.first
      sign_in org_member
      get "/credits"
      expect(response.body).to include("You have")
      expect(response.body).not_to include(CGI.escapeHTML(org.name))
    end

    it "shows credits page if user belongs to an org and is org admin" do
      org = org_admin.organizations.first
      sign_in org_admin
      get "/credits"
      expect(response.body).to include(CGI.escapeHTML(org.name))
    end

    context "when the user has made purchases that will appear in the ledger" do
      let(:params) { { spent: true, spent_at: Time.current } }

      it "shows listing purchases" do
        listing = create(:listing, user: user, title: "Awesome opportunity")
        purchase_params = { user: user, purchase_type: listing.class.name, purchase_id: listing.id }
        create(:credit, params.merge(purchase_params))

        sign_in user
        get credits_path

        expect(response.body).to include("Purchase history")
        expect(response.body).to include("Listing")
        expect(response.body).to include(listing.title)
      end

      it "shows unattributed purchases" do
        purchase_params = { user: user }
        create(:credit, params.merge(purchase_params))

        sign_in user
        get credits_path

        expect(response.body).to include("Purchase history")
        expect(response.body).to include("Miscellaneous items")
      end
    end
  end

  describe "POST credits" do
    let(:user) { create(:user) }
    let(:org_admin) { create(:user, :org_admin) }
    let(:admin_org_id) { org_admin.organizations.first.id }
    let(:stripe_helper) { StripeMock.create_test_helper }

    def charges(customer)
      Stripe::Charge.list(customer: customer.id)
    end

    before do
      StripeMock.start
      sign_in user
    end

    after do
      StripeMock.stop
    end

    it "creates unspent credits" do
      post "/credits", params: {
        credit: {
          number_to_purchase: 25
        },
        stripe_token: stripe_helper.generate_card_token
      }
      expect(user.credits.where(spent: false).size).to eq(25)
    end

    it "makes a valid Stripe charge" do
      post "/credits", params: {
        credit: {
          number_to_purchase: 20
        },
        stripe_token: stripe_helper.generate_card_token
      }
      customer = Payments::Customer.get(user.stripe_id_code)
      expect(charges(customer).first.amount).to eq 8000
    end

    context "when a user already has a card" do
      before do
        customer = Payments::Customer.create(email: user.email)
        user.update_column(:stripe_id_code, customer.id)
        customer.sources.create(source: stripe_helper.generate_card_token)
      end

      it "makes a valid Stripe charge" do
        customer = Payments::Customer.get(user.stripe_id_code)
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          selected_card: customer.sources.first.id
        }
        expect(charges(customer).first.amount).to eq 8000
      end

      it "creates unspent credits" do
        customer = Payments::Customer.get(user.stripe_id_code)
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          selected_card: customer.sources.first.id
        }
        expect(user.credits.where(spent: false).size).to eq(20)
      end

      it "charges a new card if given one" do
        post "/credits", params: {
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        customer = Payments::Customer.get(user.stripe_id_code)
        card_id = customer.sources.data.last.id
        expect(charges(customer).first.source.id).to eq card_id
      end
    end

    context "when purchasing as an organization" do
      before { sign_in org_admin }

      it "creates unspent credits for the organization" do
        post "/credits", params: {
          organization_id: admin_org_id,
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(Credit.where(organization_id: admin_org_id, spent: false).size).to eq 20
      end

      it "makes a valid Stripe charge" do
        post "/credits", params: {
          organization_id: admin_org_id,
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        customer = Payments::Customer.get(org_admin.stripe_id_code)
        expect(charges(customer).first.amount).to eq 8000
      end

      it "does not create unspent credits for the current_user" do
        post "/credits", params: {
          organization_id: admin_org_id,
          credit: {
            number_to_purchase: 20
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(org_admin.credits.where(spent: false).size).to eq 0
      end
    end

    context "when payment fails" do
      it "does not reward credits" do
        StripeMock.prepare_card_error(:card_declined, :new_charge)

        post "/credits", params: {
          credit: {
            number_to_purchase: 25
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(user.credits.where(spent: false).size).to eq(0)
      end

      it "does not reward credits for orgs" do
        sign_in org_admin

        StripeMock.prepare_card_error(:card_declined, :new_charge)

        post "/credits", params: {
          organization_id: admin_org_id,
          credit: {
            number_to_purchase: 25
          },
          stripe_token: stripe_helper.generate_card_token
        }
        expect(Credit.where(organization_id: admin_org_id, spent: false).size).to eq(0)
      end
    end
  end
end
