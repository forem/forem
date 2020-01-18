require "rails_helper"

RSpec.describe "Api::V0::Comments", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  let_it_be(:article) { create(:article) }
  let_it_be(:root_comment) { create(:comment, commentable: article) }
  let_it_be(:child_comment) { create(:comment, commentable: article, parent: root_comment) }
  let_it_be(:grandchild_comment) { create(:comment, commentable: article, parent: child_comment) }
  let_it_be(:great_grandchild_comment) { create(:comment, commentable: article, parent: grandchild_comment) }

  describe "GET /api/comments" do
    it "returns not found if wrong article id" do
      get "/api/comments?a_id=gobbledygook"
      expect(response).to have_http_status(:not_found)
    end

    it "returns comments for article" do
      get "/api/comments?a_id=#{article.id}"
      expect(json_response.size).to eq(1)
    end

    it "does not include children comments in the root list" do
      get "/api/comments?a_id=#{article.id}"
      expected_ids = article.comments.roots.map(&:id_code_generated)
      expect(json_response.map { |cm| cm["id_code"] }).to match_array(expected_ids)
    end

    it "includes children comments in the children list" do
      get "/api/comments?a_id=#{article.id}"
      comment_with_children = json_response.detect { |cm| cm["id_code"] == root_comment.id_code_generated }
      expect(comment_with_children["children"][0]["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes grandchildren comments in the children-children list" do
      get "/api/comments?a_id=#{article.id}"

      comment_with_descendants = json_response.detect { |cm| cm["id_code"] == root_comment.id_code_generated }
      expect(comment_with_descendants["children"][0]["children"][0]["id_code"]).to eq(grandchild_comment.id_code_generated)
    end

    it "includes great-grandchildren comments in the children-children-children list" do
      get "/api/comments?a_id=#{article.id}"

      comment_with_descendants = json_response.detect { |cm| cm["id_code"] == root_comment.id_code_generated }
      json_great_grandchild_id_code = comment_with_descendants["children"][0]["children"][0]["children"][0]["id_code"]
      expect(json_great_grandchild_id_code).to eq(great_grandchild_comment.id_code_generated)
    end

    it "sets the correct edge caching surrogate key for all the comments" do
      sibling_root_comment = create(:comment, commentable: article)

      get "/api/comments?a_id=#{article.id}"

      expected_key = [
        article.record_key, "comments", sibling_root_comment.record_key,
        root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "GET /api/comments/:id" do
    it "returns not found if wrong comment id" do
      get "/api/comments/foobar"
      expect(response).to have_http_status(:not_found)
    end

    it "returns the comment" do
      get "/api/comments/#{root_comment.id_code_generated}"
      expect(json_response["id_code"]).to eq(root_comment.id_code_generated)
    end

    it "includes children comments in the children list" do
      get "/api/comments/#{root_comment.id_code_generated}"

      comment_with_children = json_response
      expect(comment_with_children["children"][0]["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes grandchildren comments in the children-children list" do
      get "/api/comments/#{root_comment.id_code_generated}"

      comment_with_descendants = json_response
      expect(comment_with_descendants["children"][0]["children"][0]["id_code"]).to eq(grandchild_comment.id_code_generated)
    end

    it "includes great-grandchildren comments in the children-children-children list" do
      get "/api/comments/#{root_comment.id_code_generated}"

      comment_with_descendants = json_response
      json_great_grandchild_id_code = comment_with_descendants["children"][0]["children"][0]["children"][0]["id_code"]
      expect(json_great_grandchild_id_code).to eq(great_grandchild_comment.id_code_generated)
    end

    it "sets the correct edge caching surrogate key for all the comments" do
      get "/api/comments/#{root_comment.id_code_generated}"

      expected_key = [
        "comments", root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end
end
