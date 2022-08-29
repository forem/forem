require "rails_helper"

RSpec.describe "Api::V1::Comments", type: :request do
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:article) { create(:article) }
  let!(:root_comment) { create(:comment, commentable: article) }
  let!(:child_comment) do
    create(:comment, commentable: article, parent: root_comment)
  end
  let!(:grandchild_comment) do
    create(:comment, commentable: article, parent: child_comment)
  end
  let!(:great_grandchild_comment) do
    create(:comment, commentable: article, parent: grandchild_comment)
  end

  def find_root_comment(response)
    response.parsed_body.detect do |cm|
      cm["id_code"] == root_comment.id_code_generated
    end
  end

  def find_child_comment(response, action = :index)
    body = response.parsed_body

    root_comment_json = if action == :index
                          body.detect do |cm|
                            cm["id_code"] == root_comment.id_code_generated
                          end
                        else
                          body
                        end

    root_comment_json["children"].detect do |cm|
      cm["id_code"] == child_comment["id_code"]
    end
  end

  describe "GET /api/comments" do
    it "returns not found if wrong article id" do
      get api_comments_path(a_id: "gobbledygook"), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns comments for article" do
      get api_comments_path(a_id: article.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end

    it "does not include children comments in the root list" do
      get api_comments_path(a_id: article.id), headers: headers

      expected_ids = article.comments.roots.map(&:id_code_generated)
      response_ids = response.parsed_body.map { |cm| cm["id_code"] }
      expect(response_ids).to match_array(expected_ids)
    end

    it "includes children comments in the children list" do
      get api_comments_path(a_id: article.id), headers: headers

      child_comment_json = find_child_comment(response)
      expect(child_comment_json["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes grandchildren comments in the children-children list" do
      get api_comments_path(a_id: article.id), headers: headers

      root_comment_json = find_root_comment(response)
      grandchild_comment_json_id = root_comment_json.dig(
        "children", 0, "children", 0, "id_code"
      )
      expect(grandchild_comment_json_id).to eq(grandchild_comment.id_code_generated)
    end

    it "includes great-grandchildren comments in the children-children-children list" do
      get api_comments_path(a_id: article.id), headers: headers

      root_comment_json = find_root_comment(response)
      great_grandchild_comment_json_id = root_comment_json.dig(
        "children", 0, "children", 0, "children", 0, "id_code"
      )
      expect(great_grandchild_comment_json_id).to eq(great_grandchild_comment.id_code_generated)
    end

    it "sets the correct edge caching surrogate key for all the comments" do
      sibling_root_comment = create(:comment, commentable: article)

      get api_comments_path(a_id: article.id), headers: headers

      expected_key = [
        article.record_key, "comments", sibling_root_comment.record_key,
        root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    it "returns date created" do
      get api_comments_path(a_id: article.id), headers: headers
      expect(find_root_comment(response)).to include(
        "created_at" => root_comment.created_at.utc.iso8601,
      )
    end

    context "when a comment is deleted" do
      before do
        child_comment.update(deleted: true)
      end

      it "appears in the thread" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["id_code"]).to eq(child_comment.id_code_generated)
      end

      it "replaces the body_html" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["body_html"]).to eq("<p>#{Comment.title_deleted}</p>")
      end

      it "does not render the user information" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["user"]).to be_empty
      end

      it "still has children comments" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["children"]).not_to be_empty
      end
    end

    context "when a comment is hidden" do
      before do
        child_comment.update(hidden_by_commentable_user: true)
      end

      it "appears in the thread" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["id_code"]).to eq(child_comment.id_code_generated)
      end

      it "replaces the body_html" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["body_html"]).to eq("<p>#{Comment.title_hidden}</p>")
      end

      it "does not render the user information" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["user"]).to be_empty
      end

      it "still has children comments" do
        get api_comments_path(a_id: article.id), headers: headers

        expect(find_child_comment(response)["children"]).not_to be_empty
      end
    end

    context "when getting by podcast episode id" do
      let(:podcast) { create(:podcast) }
      let(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
      let(:comment) { create(:comment, commentable: podcast_episode) }

      before { comment }

      it "not found if bad podcast episode id" do
        get api_comments_path(p_id: "asdfghjkl"), headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns comment if good podcast episode id" do
        get api_comments_path(p_id: podcast_episode.id), headers: headers
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
      end
    end
  end

  describe "GET /api/comments/:id" do
    it "returns not found if wrong comment id" do
      get api_comment_path("foobar"), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns the comment" do
      get api_comment_path(root_comment.id_code_generated), headers: headers
      expect(response).to have_http_status(:ok)

      expect(response.parsed_body["id_code"]).to eq(root_comment.id_code_generated)
    end

    it "includes children comments in the children list" do
      get api_comment_path(root_comment.id_code_generated), headers: headers

      expect(find_child_comment(response, :show)["id_code"]).to eq(child_comment.id_code_generated)
    end

    it "includes grandchildren comments in the children-children list" do
      get api_comment_path(root_comment.id_code_generated), headers: headers

      grandchild_comment_json_id = response.parsed_body.dig(
        "children", 0, "children", 0, "id_code"
      )
      expect(grandchild_comment_json_id).to eq(grandchild_comment.id_code_generated)
    end

    it "includes great-grandchildren comments in the children-children-children list" do
      get api_comment_path(root_comment.id_code_generated), headers: headers

      great_grandchild_comment_json_id = response.parsed_body.dig(
        "children", 0, "children", 0, "children", 0, "id_code"
      )
      expect(great_grandchild_comment_json_id).to eq(great_grandchild_comment.id_code_generated)
    end

    it "sets the correct edge caching surrogate key for all the comments" do
      get api_comment_path(root_comment.id_code_generated), headers: headers

      expected_key = [
        "comments", root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    context "when a comment is deleted" do
      before do
        child_comment.update(deleted: true)
      end

      it "appears in the thread" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["id_code"]).to eq(child_comment.id_code_generated)
      end

      it "replaces the body_html" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["body_html"]).to eq("<p>[deleted]</p>")
      end

      it "does not render the user information" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["user"]).to be_empty
      end

      it "still has children comments" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["children"]).not_to be_empty
      end
    end

    context "when a comment is hidden" do
      before do
        child_comment.update(hidden_by_commentable_user: true)
      end

      it "appears in the thread" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["id_code"]).to eq(child_comment.id_code_generated)
      end

      it "replaces the body_html" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["body_html"]).to eq("<p>[hidden by post author]</p>")
      end

      it "does not render the user information" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["user"]).to be_empty
      end

      it "still has children comments" do
        get api_comment_path(root_comment.id_code_generated), headers: headers

        expect(find_child_comment(response, :show)["children"]).not_to be_empty
      end
    end
  end
end
