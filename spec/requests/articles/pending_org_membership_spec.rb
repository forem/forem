require "rails_helper"

RSpec.describe "Pending organization membership" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  def membership(type_of_user)
    create(:organization_membership, user: user, organization: organization, type_of_user: type_of_user)
  end

  describe "the editor organization list" do
    before { sign_in user }

    it "omits an organization the user is only invited to" do
      membership("pending")

      get new_path

      expect(assigns(:organizations)).not_to include(organization)
    end

    it "includes an organization the user is a member of" do
      membership("member")

      get new_path

      expect(assigns(:organizations)).to include(organization)
    end
  end

  describe "posting under an organization" do
    before { sign_in user }

    it "refuses to attach the organization while the invite is pending" do
      membership("pending")

      post articles_path, params: {
        article: { title: "Title", body_markdown: "Body", organization_id: organization.id }
      }

      expect(Article.last&.organization_id).to be_nil
    end

    it "attaches the organization for an accepted member" do
      membership("member")

      post articles_path, params: {
        article: { title: "Title", body_markdown: "Body", organization_id: organization.id }
      }

      expect(Article.last&.organization_id).to eq(organization.id)
    end
  end
end
