require "rails_helper"

RSpec.describe "/users/invitation", type: :request do
  # let(:user) { create(:user, registered: false, invitation_token: "#{rand(1000)}") }
  let(:user) { create(:user, registered: false) }

  describe "PUT /users/invitation" do
    it "updates the user's 'registered' column upon invite acceptance" do
      user.invite!
      # image_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg")
      # user = User.invite!(email: "hey#{rand(1000)}@email.co",
      #                     name: "Roger #{rand(1000)}",
      #                     username: "rogerabc",
      #                     remote_profile_image_url: Rack::Test::UploadedFile.new(image_path, "image/jpeg"),
      #                     saw_onboarding: false,
      #                     editor_version: :v2,
      #                     registered: false)
      # remote_profile_image_url: Rack::Test::UploadedFile.new(image_path, "image/jpeg"),
      #   user.accept_invitation!
      #   user.accept_invitation!(invitation_token: params[user.invitation_token])
      put "/users/invitation", params: { user:
                              { invitation_token: user.invitation_token, password: user.password,
                                password_confirmation: user.password } }
      expect(user.reload.registered).to be(true)
    end
  end
end
