module FavoritesHelper
  # Emits the mount node for the Preact FavoriteControl with initial server-rendered markup
  def favorite_control_tag(favoritable, variant: :article)
    return unless FeatureFlag.enabled?(:community_favorites)

    favoritable = favoritable.object if favoritable.try(:decorated?)

    favorited = favoritable.favorited_by_user_id.present?
    label = favorited ? t("favorites.favorited") : t("favorites.favorite")

    inner_content = case variant.to_sym
                    when :article
                      if favorited
                        tag.span(
                          class: "favorite-reaction favorite-control favorite-control--favorited crayons-tooltip__activator relative",
                          role: "img",
                          aria: { label: label },
                        ) do
                          concat tag.span(crayons_icon_tag("favorite-filled", native: true), class: "crayons-reaction__icon crayons-reaction__icon--borderless")
                          concat tag.span(label, data: { testid: "tooltip" }, class: "crayons-tooltip__content")
                        end
                      else
                        tag.button(
                          type: "button",
                          class: "favorite-reaction favorite-control crayons-tooltip__activator relative",
                          aria: { label: label },
                        ) do
                          concat tag.span(crayons_icon_tag("favorite", native: true), class: "crayons-reaction__icon crayons-reaction__icon--borderless")
                          concat tag.span(label, data: { testid: "tooltip" }, class: "crayons-tooltip__content")
                        end
                      end
                    when :dropdown
                      if favorited
                        tag.span(
                          class: "flex justify-between crayons-link crayons-link--block w-100 bg-transparent border-0 favorite-control favorite-control--favorited",
                          role: "img",
                          aria: { label: label },
                        ) do
                          concat tag.span(label, class: "fw-bold")
                          concat crayons_icon_tag("small-favorite-filled", native: true, class: "mx-2 shrink-0")
                        end
                      else
                        tag.button(
                          type: "button",
                          class: "flex justify-between crayons-link crayons-link--block w-100 bg-transparent border-0 favorite-control",
                          aria: { label: label },
                        ) do
                          concat tag.span(label, class: "fw-bold")
                          concat crayons_icon_tag("small-favorite", native: true, class: "mx-2 shrink-0")
                        end
                      end
                    when :comment
                      if favorited
                        tag.span(
                          class: "crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon favorite-control favorite-control--favorited crayons-tooltip__activator relative",
                          role: "img",
                          aria: { label: label },
                        ) do
                          concat crayons_icon_tag("small-favorite-filled", native: true)
                          concat tag.span(label, data: { testid: "tooltip" }, class: "crayons-tooltip__content")
                        end
                      end
                    end

    tag.span(
      class: "favorite-control-root",
      data: {
        favorite_control: true,
        variant: variant,
        favoritable_type: favoritable.class.name,
        favoritable_id: favoritable.id,
        favoritable_user_id: favoritable.user_id,
        favorited: favorited,
        favorited_by_user_id: favoritable.favorited_by_user_id,
        label_favorite: t("favorites.favorite"),
        label_favorited: t("favorites.favorited"),
        label_favorited_by_you: t("favorites.favorited_by_you")
      },
    ) do
      inner_content
    end
  end
end
