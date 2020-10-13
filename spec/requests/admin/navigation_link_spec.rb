require "rails_helper"

RSpec.describe "NavigationLinks", type: :request do
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in admin
  end

  describe "GET /admin/navigation_link" do
    let(:navigation_link) { create(:navigation_link) }

    it "returns a successful response" do
      get admin_navigation_links_path
      expect(response.status).to eq 200
    end
  end

  describe "POST /admin/navigation_link" do
    let(:new_navigation_link) do
      {
        name: "Test 2",
        url: "https://www.test2.com",
        icon: "<svg height='10'></svg>"
      }
    end

    it "redirects successfully" do
      post admin_navigation_links_path, params: { navigation_link: new_navigation_link }
      expect(response).to redirect_to admin_navigation_links_path
    end

    it "creates a navigation link" do
      expect do
        post admin_navigation_links_path, params: { navigation_link: new_navigation_link }
      end.to change { NavigationLink.all.count }.by(1)

      last_navigation_link_record = NavigationLink.last
      expect(last_navigation_link_record.name).to eq(new_navigation_link[:name])
      expect(last_navigation_link_record.url).to eq(new_navigation_link[:url])
      expect(last_navigation_link_record.icon).to eq(new_navigation_link[:icon])
    end
  end

  describe "PUT /admin/navigation_links/:id" do
    let(:navigation_link) { create(:navigation_link) }

    it "redirects successfully" do
      put "#{admin_navigation_links_path}/#{navigation_link.id}",
          params: { navigation_link: { name: "Example" } }
      expect(response).to redirect_to admin_navigation_links_path
    end

    it "updates the profile field values" do
      put "#{admin_navigation_links_path}/#{navigation_link.id}",
          params: { navigation_link: { name: "Example" } }

      changed_navigation_link_record = NavigationLink.find(navigation_link.id)
      expect(changed_navigation_link_record.name).to eq("Example")
    end
  end

  describe "DELETE /admin/navigation_links/:id" do
    let!(:navigation_link) { create(:navigation_link) }

    it "redirects successfully" do
      delete "#{admin_navigation_links_path}/#{navigation_link.id}"
      expect(response).to redirect_to admin_navigation_links_path
    end

    it "removes a navigation_link" do
      expect do
        delete "#{admin_navigation_links_path}/#{navigation_link.id}"
      end.to change(NavigationLink, :count).by(-1)
    end
  end
end
