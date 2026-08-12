module FavoritesHelper
  # Emits the mount node for the Preact FavoriteControl
  def favorite_control_tag(favoritable, variant: :article)
    favoritable = favoritable.object if favoritable.try(:decorated?)

    tag.span(
      class: "favorite-control-root",
      data: {
        favorite_control: true,
        variant: variant,
        favoritable_type: favoritable.class.name,
        favoritable_id: favoritable.id,
        favoritable_user_id: favoritable.user_id,
        favorited: favoritable.favorited_by_user_id.present?,
        favorited_by_user_id: favoritable.favorited_by_user_id,
        label_favorite: t("favorites.favorite"),
        label_favorited: t("favorites.favorited"),
        label_favorited_by_you: t("favorites.favorited_by_you")
      },
    )
  end
end
