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

      { "#{name}.json" => jsonify(comments) }
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

    def jsonify(comments)
      comments_to_jsonify = []

      # the commentable polymorphic attributes are added to the select for the "includes" to work
      attributes_to_select = %i[id commentable_id commentable_type] + allowed_attributes
      comments.includes(:commentable).select(attributes_to_select).find_each do |comment|
        # merge final json with the path of the commentable
        comments_to_jsonify << comment.as_json(only: allowed_attributes).
          merge(commentable_path: comment.commentable&.path)
      end

      comments_to_jsonify.to_json
    end
  end
end
