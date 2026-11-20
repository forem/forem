require "rails_helper"

RSpec.describe "Admin::LinkedDomains" do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let!(:linked_domain) { LinkedDomain.create!(host: "example.com", net_score: 500) }

  describe "GET /admin/moderation/linked_domains" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
        get admin_linked_domains_path
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "displays the linked domains" do
        expect(response.body).to include("example.com")
        expect(response.body).to include("500")
      end

      it "orders by reverse id, avoids unindexed total COUNT(*), and caches threshold counts", :aggregate_failures do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        newer_domain = LinkedDomain.create!(host: "newer-example.org", net_score: -3000)

        queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          sql = payload[:sql].to_s
          next if payload[:name] == "SCHEMA" || payload[:cached]

          queries << sql if sql.include?('"linked_domains"')
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get admin_linked_domains_path
        end

        expect(response).to have_http_status(:success)
        expect(response.body.index("newer-example.org")).to be < response.body.index("example.com")
        expect(queries.grep(/ORDER BY "linked_domains"\."id" DESC/i).size).to eq(1)
        expect(queries.grep(/ORDER BY "linked_domains"\."created_at"/i)).to be_empty
        expect(queries.grep(/\ASELECT COUNT\(\*\) FROM "linked_domains"\z/i)).to be_empty
        expect(queries.grep(/SELECT COUNT\(\*\) FROM "linked_domains" WHERE/i).size).to eq(1)

        repeat_queries = []
        repeat_callback = lambda do |_name, _start, _finish, _id, payload|
          sql = payload[:sql].to_s
          next if payload[:name] == "SCHEMA" || payload[:cached]

          repeat_queries << sql if sql.include?('"linked_domains"')
        end

        ActiveSupport::Notifications.subscribed(repeat_callback, "sql.active_record") do
          get admin_linked_domains_path
        end

        expect(repeat_queries.grep(/SELECT COUNT\(\*\) FROM "linked_domains"/i)).to be_empty
        expect(response.body).to include("1 domain</strong> currently at or below")

        patch admin_linked_domain_path(newer_domain), params: {
          linked_domain: { manual_setting: "ignored" }
        }
        get admin_linked_domains_path
        expect(response.body).to include("0 domains</strong> currently at or below")
      end
    end

    context "when signed in as a regular user" do
      before do
        sign_in user
      end

      it "raises NotAuthorizedError" do
        expect { get admin_linked_domains_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/moderation/linked_domains/:id/edit" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
        get edit_admin_linked_domain_path(linked_domain)
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        expect(response.body).to include("Edit Linked Domain: example.com")
      end
    end
  end

  describe "PATCH /admin/moderation/linked_domains/:id" do
    context "when signed in as a tech admin" do
      before do
        sign_in admin
      end

      it "updates the manual setting and redirects" do
        patch admin_linked_domain_path(linked_domain), params: {
          linked_domain: { manual_setting: "ignored" }
        }

        expect(response).to redirect_to(admin_linked_domains_path)
        expect(linked_domain.reload.ignored?).to be true
        expect(linked_domain.net_score).to eq(0)
      end
    end

    context "when signed in as a regular user" do
      before do
        sign_in user
      end

      it "raises NotAuthorizedError and does not update" do
        expect do
          patch admin_linked_domain_path(linked_domain), params: {
            linked_domain: { manual_setting: "ignored" }
          }
        end.to raise_error(Pundit::NotAuthorizedError)

        expect(linked_domain.reload.not_set?).to be true
      end
    end
  end

  describe "PATCH /admin/moderation/linked_domains/spam_threshold" do
    context "when signed in as an admin" do
      before { sign_in admin }

      after { Settings::RateLimit.clear_cache }

      it "updates the domain abuse score threshold" do
        patch spam_threshold_admin_linked_domains_path, params: { linked_domain_spam_score_threshold: 3500 }
        expect(response).to redirect_to(admin_linked_domains_path)
        expect(Settings::RateLimit.linked_domain_spam_score_threshold).to eq(3500)
      end

      it "rejects non-positive values" do
        patch spam_threshold_admin_linked_domains_path, params: { linked_domain_spam_score_threshold: 0 }
        expect(response).to redirect_to(admin_linked_domains_path)
        expect(Settings::RateLimit.linked_domain_spam_score_threshold).to eq(2000)
      end

      it "rejects non-integer values instead of coercing them" do
        patch spam_threshold_admin_linked_domains_path, params: { linked_domain_spam_score_threshold: "1e3" }
        expect(response).to redirect_to(admin_linked_domains_path)
        expect(flash[:alert]).to eq("Threshold must be a whole number.")
        expect(Settings::RateLimit.linked_domain_spam_score_threshold).to eq(2000)
      end

      it "shows the threshold explanation on the index" do
        get admin_linked_domains_path
        expect(response.body).to include("Domain abuse score threshold")
        expect(response.body).to include("4 spam posts")
      end
    end

    context "when signed in as a regular user" do
      before { sign_in user }

      it "raises NotAuthorizedError" do
        expect do
          patch spam_threshold_admin_linked_domains_path, params: { linked_domain_spam_score_threshold: 10 }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
