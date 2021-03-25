module Search
  class ReadingListArticleSerializer < ApplicationSerializer
    attribute :id, &:reaction_id
    attribute :user_id, &:reaction_user_id

    # NOTE: the list of attributes for `reactable` comes from two places:
    # => the `<ItemListItem>` Preact component: https://github.com/forem/forem/blob/33d0e03dbd94fc6797693b84fcafb5040ea399d0/app/javascript/readingList/components/ItemListItem.jsx#L72-L85
    # => the `performInitialSearch` function: https://github.com/forem/forem/blob/33d0e03dbd94fc6797693b84fcafb5040ea399d0/app/javascript/searchableItemList/searchableItemList.js#L78
    attribute :reactable do |article, params|
      user = params[:users][article.user_id]
      tags = article.cached_tag_list.to_s.split(", ")

      {
        path: article.path,
        readable_publish_date_string: article.readable_publish_date,
        reading_time: article.reading_time,

        # TODO: once we switch to PG we should revisit how we handle tags in the
        # frontend, we're sending back tags twice in slightly different formats
        tag_list: tags,
        tags: tags.map { |tag| { name: tag } },

        title: article.title,

        # NOTE: not using the `NestedUserSerializer` because we don't need the
        # the `pro` flag on the frontend, and we also avoid hitting Redis to
        # fetch the cached value
        user: {
          name: user.name,
          profile_image_90: user.profile_image_90,
          username: user.username
        }
      }
    end
  end
end
