module Comments
  class Tree
    include ActionView::Context

    def initialize(context:, comment:, sub_comments:, commentable:)
      @context = context
      @comment = comment
      @sub_comments = sub_comments
      @commentable = commentable
    end

    def display
      nested_comments(tree: { comment => sub_comments }, commentable: commentable, is_view_root: true)
    end

    private

    attr_reader :context, :comment, :sub_comments, :commentable

    def nested_comments(tree:, commentable:, is_view_root: false)
      tree.map do |comment, sub_comments|
        context.render("comments/comment", comment: comment, commentable: commentable,
                                           is_view_root: is_view_root, is_childless: sub_comments.empty?,
                                           subtree_html: nested_comments(tree: sub_comments, commentable: commentable))
      end.join.html_safe
    end
  end
end
