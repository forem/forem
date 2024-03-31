module Moderations
  module ActionsPanelHelper
    def last_adjusted_by_admin?(article, tag, adjustment_type)
      last_user_id = TagAdjustment.where(article_id: article.id, adjustment_type: adjustment_type, status: "committed",
                                         tag_id: tag.id)
        .last&.user_id
      User.find_by(id: last_user_id)&.any_admin?
    end
  end
end
