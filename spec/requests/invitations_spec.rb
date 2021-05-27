require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:user) { create(:user) }

  describe "Accept invitation" do
    it "renders normal response even if the Forem instance is private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      get "/users/invitation/accept?invitation_token=blahblahblahblah"
      # This is a fake token, so the only thing we're testing for here is
      # that we *do not* land on the "registrations" page which shouldn't
      # interrupt the request, even for private forems.
      expect(response.body).not_to include("registration__actions")
    end
  end
end
