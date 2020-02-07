require "rails_helper"

RSpec.describe Exporter::Comments, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:podcast_episode) { create(:podcast_episode) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:podcast_episode_comment) { create(:comment, user: user, commentable: podcast_episode) }
  let(:other_user) { create(:user) }
  let(:other_user_comment) { create(:comment, user: other_user, commentable: article) }

  def valid_instance(user)
    described_class.new(user)
  end

  def expected_fields
    %w[
      body_markdown
      created_at
      deleted
      edited
      edited_at
      id_code
      markdown_character_count
      positive_reactions_count
      processed_html
      receive_notifications
      commentable_path
    ]
  end

  def load_comments(data)
    JSON.parse(data["comments.json"])
  end

  describe "#initialize" do
    it "accepts a user" do
      exporter = valid_instance(user)
      expect(exporter.user).to be(user)
    end

    it "names itself comments" do
      exporter = valid_instance(user)
      expect(exporter.name).to eq(:comments)
    end
  end

  describe "#export" do
    context "when id code is unknown" do
      it "returns no comments if the id code is not found" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: "not found")
        comments = load_comments(result)
        expect(comments).to be_empty
      end

      it "no comments if id code belongs to another user" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: other_user_comment.id_code)
        comments = load_comments(result)
        expect(comments).to be_empty
      end
    end

    context "when id code is known" do
      it "returns the comment" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: comment.id_code)
        comments = load_comments(result)
        expect(comments.length).to eq(1)
      end

      it "returns only expected fields for the comment" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: comment.id_code)
        comments = load_comments(result)
        expect(comments.first.keys).to match_array(expected_fields)
      end
    end

    context "when all comments are requested" do
      it "returns all the comments as json" do
        exporter = valid_instance(comment.user)
        result = exporter.export
        comments = load_comments(result)
        user.reload
        expect(comments.length).to eq(user.comments.size)
      end

      it "returns only expected fields for the comment" do
        exporter = valid_instance(comment.user)
        result = exporter.export
        comments = load_comments(result)
        expect(comments.first.keys).to match_array(expected_fields)
      end
    end

    describe "commentable path" do
      it "contains the path of the article" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: comment.id_code)
        comments = load_comments(result)
        expect(comments.first["commentable_path"]).to eq(article.path)
      end

      it "contains the path of the podcast episode" do
        exporter = valid_instance(user)
        result = exporter.export(id_code: podcast_episode_comment.id_code)
        comments = load_comments(result)
        expect(comments.first["commentable_path"]).to eq(podcast_episode.path)
      end
    end
  end
end
