module Comments
  class CommentJob < ApplicationJob
    queue_as :default

    def self.perform_later(*args)
      super unless Rails.env.development?
    end

    def perform(comment_id, method, *args)
      comment = Comment.find_by(id: comment_id)
      comment&.public_send(method.to_sym, *args)
    end
  end
end
