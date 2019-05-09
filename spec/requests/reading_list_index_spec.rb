require "rails_helper"

RSpec.describe "ReadingListIndex", type: :request do
  before do
    user = create(:user)
    sign_in user
  end

  describe "GET reading list" do
    xit "returns reading list page" do
      get "/readinglist"
      expect(response.body).to include("R")
    end
  end
end
