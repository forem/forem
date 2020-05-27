require "rails_helper"

RSpec.describe "Blocks", type: :request do
  let(:user) { create(:user, :super_admin) }

  before { sign_in user }

  describe "GET blocks index" do
    xit "renders proper blocks index" do
      create(:block, user_id: user.id, input_css: ".blue { color: blue;}")
      get "/blocks"
      expect(response.body).to include("color: blue")
    end
  end

  describe "POST blocks" do
    xit "creates block from input data" do
      post "/blocks", params: {
        block: {
          input_css: ".blue { color: blue;}",
          input_html: "yo",
          input_javascript: "alert('hey')"
        }
      }
      expect(Block.all.size).to eq(1)
    end
  end

  describe "PUT blocks" do
    xit "updates block from input data" do
      block = create(:block, user_id: user.id, input_css: ".blue { color: blue;}")
      put "/blocks/#{block.id}", params: {
        block: { input_css: ".blue { color: red;}",
                 input_html: "yo",
                 input_javascript: "alert('hey')" }
      }
      expect(Block.last.processed_css).to include("color: red")
    end
  end

  describe "DELETE blocks" do
    xit "updates block from input data" do
      block = create(:block, user_id: user.id, input_css: ".blue { color: blue;}")
      delete "/blocks/#{block.id}"
      expect(Block.all.size).to eq(0)
    end
  end
end
