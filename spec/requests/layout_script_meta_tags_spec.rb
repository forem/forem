require "rails_helper"

RSpec.describe "Layout deferred script meta tags" do
  describe "GET /" do
    it "renders deferred script meta tags for on-demand bundles" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="mermaid-script"')
      expect(response.body).to include('name="comment-textarea-script"')
      expect(response.body).to include("CommentTextArea/CommentTextArea")
    end
  end
end
