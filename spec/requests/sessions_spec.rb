require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /users/sign_out" do
    it "shows the sign in page (with self-serve auth)" do
      sign_in user
      # p response.cookies.to_json
      # p response.cookies.size
      # set_cookie "foo=red"
      delete "/sign_out"
      p response.cookies.to_json
      p response.cookies.to_json
      p response.cookies.to_json
      p response.cookies.to_json
      p response.cookies.to_json
      p response.cookies.to_json
      expect(response.cookies.size).to be 0
    end
  end
end
