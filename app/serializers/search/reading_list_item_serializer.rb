module Search
  class ReadingListItemSerializer < ApplicationSerializer
    attribute :id, &:reaction_id
    attribute :user_id, &:reaction_user_id

    attribute :reactable do |item, params|
      user = params[:users][item.user_id]

      tags = item.cached_tag_list.to_s.split(", ")

      {
        path: item.path,
        readable_publish_date_string: item.readable_publish_date,
        reading_time: item.reading_time,

        # TODO: once we switch to PG we should revisit how we handle tags in the
        # frontend, we're sending back tags twice in slightly different formats
        tag_list: tags,
        tags: tags.map { |tag| { name: tag } },

        title: item.title,

        user: {
          name: user.name,
          profile_image_90: user.profile_image_90,
          username: user.username
        }
      }
    end
  end
end
