module Search
  class ReadingListArticleSerializer < ApplicationSerializer
    attribute :id, &:reaction_id
    attribute :user_id, &:reaction_user_id

    attribute :reactable do |article|
      # NOTE: [@rhymes] to be replaced when we establish which fields the frontend
      # actually needs
      Search::ArticleSerializer.new(article).serializable_hash.dig(:data, :attributes)
    end
  end
end
