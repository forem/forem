module Exporter
  class Comments
    attr_reader :name
    attr_reader :user

    def initialize(user)
      @name = :comments
      @user = user
    end

    def export(id_code: nil)
      comments = user.comments
      comments = comments.where(id_code: id_code) if id_code.present?
      json_comments = jsonify_comments(comments)

      { "#{name}.json" => json_comments }
    end

    private

    def allowed_attributes
      %i[
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
      ]
    end

    def jsonify_comments(comments)
      comments_to_jsonify = []
      # load comments in batches, we don't want to hog the DB
      # if a user has lots and lots of comments
      comments.find_each do |comment|
        comments_to_jsonify << comment
      end
      comments_to_jsonify.to_json(only: allowed_attributes)
    end
  end
end
