require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/badge_categories" do
  it_behaves_like "an InternalPolicy dependant request", BadgeCategory do
    let(:request) { get admin_badge_categories_path }
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :super_admin) }
    let(:badge_category) { create(:badge_category) }
    let(:params) do
      {
        badge_category: {
          name: "Badge Category from params",
          description: "Category for Badges"
        }
      }
    end

    before do
      sign_in admin
    end

    describe "POST /admin/content_manager/badge_categories" do
      it "successfully creates a badge category" do
        expect { post admin_badge_categories_path, params: params }
          .to change(BadgeCategory, :count).by(1)
      end
    end

    describe "PUT /admin/content_manager/badge_categories/:id" do
      it "successfully updates the badge_category" do
        expect { patch admin_badge_category_path(badge_category), params: params }
          .to change { badge_category.reload.name }.to("Badge Category from params")
        expect(badge_category.description).to eq("Category for Badges")
      end
    end

    describe "DELETE /admin/content_manager/badge_categories/:id" do
      let!(:badge_category) { create(:badge_category) }

      it "deletes the badge_category" do
        expect { delete admin_badge_category_path(badge_category) }
          .to change(BadgeCategory, :count).by(-1)
      end
    end
  end
end
