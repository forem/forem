module Search
  class ReactionSerializer
    include FastJsonapi::ObjectSerializer

    attributes :id, :category, :status, :user_id

    attribute :reactable do |reaction|
      reactable = reaction.reactable
      tags = if reactable.respond_to?(:tags)
               reactable.tags.map do |tag|
                 { name: tag.name, keywords_for_search: tag.keywords_for_search }
               end
             else
               []
             end

      {
        id: reactable.id,
        body_text: reactable.respond_to?(:body_text) ? reactable.body_text : reactable.body_markdown,
        class_name: reactable.class.name,
        path: reactable.path,
        published_date_string: reactable.readable_publish_date,
        reading_time: reactable.respond_to?(:reading_time) ? reactable.reading_time : 1,
        tags: tags,
        title: reactable.title,
        user: NestedUserSerializer.new(reactable.user).serializable_hash.dig(
          :data, :attributes
        )
      }
    end
  end
end
