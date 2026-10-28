require "rails_helper"

RSpec.describe "Api::V0::Comments" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:root_comment) { create(:comment, commentable: article, user: user) }
  let(:child_comment) do
    create(:comment, commentable: article, parent: root_comment, user: user)
  end
  let(:grandchild_comment) do
    create(:comment, commentable: article, parent: child_comment, user: user)
  end
  let(:great_grandchild_comment) do
    create(:comment, commentable: article, parent: grandchild_comment, user: user)
  end

  def build_comment_tree
    great_grandchild_comment
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
      get api_comments_path(a_id: "gobbledygook")

      expect(response).to have_http_status(:not_found)
    end

    it "returns the nested comment tree and metadata for an article", :aggregate_failures do
      build_comment_tree

      get api_comments_path(a_id: article.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.pluck("id_code")).to match_array(article.comments.roots.map(&:id_code_generated))

      child_comment_json = find_child_comment(response)
      expect(child_comment_json["id_code"]).to eq(child_comment.id_code_generated)

      root_comment_json = find_root_comment(response)
      expect(root_comment_json).to include("created_at" => root_comment.created_at.utc.iso8601)
      expect(root_comment_json.dig("children", 0, "children", 0, "id_code")).to eq(
        grandchild_comment.id_code_generated,
      )
      expect(root_comment_json.dig("children", 0, "children", 0, "children", 0, "id_code")).to eq(
        great_grandchild_comment.id_code_generated,
      )
    end

    it "sets the correct edge caching surrogate key for all the comments" do
      build_comment_tree
      sibling_root_comment = create(:comment, commentable: article, user: user)

      get api_comments_path(a_id: article.id)

      expected_key = [
        article.record_key, "comments", sibling_root_comment.record_key,
        root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    context "when a comment is deleted" do
      before do
        grandchild_comment
        child_comment.update(deleted: true)
      end

      it "appears in the thread with deleted body_html, empty user, and intact children", :aggregate_failures do
        get api_comments_path(a_id: article.id)

        deleted_child = find_child_comment(response)
        expect(deleted_child["id_code"]).to eq(child_comment.id_code_generated)
        expect(deleted_child["body_html"]).to eq("<p>#{Comment.title_deleted}</p>")
        expect(deleted_child["user"]).to be_empty
        expect(deleted_child["children"]).not_to be_empty
      end
    end

    context "when a comment is hidden" do
      before do
        grandchild_comment
        child_comment.update(hidden_by_commentable_user: true)
      end

      it "appears in the thread with hidden body_html, empty user, and intact children", :aggregate_failures do
        get api_comments_path(a_id: article.id)

        hidden_child = find_child_comment(response)
        expect(hidden_child["id_code"]).to eq(child_comment.id_code_generated)
        expect(hidden_child["body_html"]).to eq("<p>#{Comment.title_hidden}</p>")
        expect(hidden_child["user"]).to be_empty
        expect(hidden_child["children"]).not_to be_empty
      end
    end

    context "when getting by podcast episode id" do
      let(:podcast) { create(:podcast) }
      let(:podcast_episode) { create(:podcast_episode, podcast: podcast) }
      let(:comment) { create(:comment, commentable: podcast_episode, user: user) }

      it "not found if bad podcast episode id" do
        get api_comments_path(p_id: "asdfghjkl")
        expect(response).to have_http_status(:not_found)
      end

      it "returns comment if good podcast episode id", :aggregate_failures do
        comment
        get api_comments_path(p_id: podcast_episode.id)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.size).to eq(1)
      end
    end
  end

  describe "GET /api/comments/:id" do
    it "returns not found if wrong comment id" do
      get api_comment_path("foobar")

      expect(response).to have_http_status(:not_found)
    end

    it "returns the comment, its nested descendants, and edge caching surrogate key", :aggregate_failures do
      build_comment_tree

      get api_comment_path(root_comment.id_code_generated)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id_code"]).to eq(root_comment.id_code_generated)
      expect(find_child_comment(response, :show)["id_code"]).to eq(child_comment.id_code_generated)
      expect(response.parsed_body.dig("children", 0, "children", 0, "id_code")).to eq(
        grandchild_comment.id_code_generated,
      )
      expect(response.parsed_body.dig("children", 0, "children", 0, "children", 0, "id_code")).to eq(
        great_grandchild_comment.id_code_generated,
      )

      expected_key = [
        "comments", root_comment.record_key, child_comment.record_key,
        grandchild_comment.record_key, great_grandchild_comment.record_key
      ].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    context "when a comment is deleted" do
      before do
        grandchild_comment
        child_comment.update(deleted: true)
      end

      it "appears in the thread with deleted body_html, empty user, and intact children", :aggregate_failures do
        get api_comment_path(root_comment.id_code_generated)

        deleted_child = find_child_comment(response, :show)
        expect(deleted_child["id_code"]).to eq(child_comment.id_code_generated)
        expect(deleted_child["body_html"]).to eq("<p>[deleted]</p>")
        expect(deleted_child["user"]).to be_empty
        expect(deleted_child["children"]).not_to be_empty
      end
    end

    context "when a comment is hidden" do
      before do
        grandchild_comment
        child_comment.update(hidden_by_commentable_user: true)
      end

      it "appears in the thread with hidden body_html, empty user, and intact children", :aggregate_failures do
        get api_comment_path(root_comment.id_code_generated)

        hidden_child = find_child_comment(response, :show)
        expect(hidden_child["id_code"]).to eq(child_comment.id_code_generated)
        expect(hidden_child["body_html"]).to eq("<p>[hidden by post author]</p>")
        expect(hidden_child["user"]).to be_empty
        expect(hidden_child["children"]).not_to be_empty
      end
    end
  end
end
