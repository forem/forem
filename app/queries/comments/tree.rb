module Comments
  class Tree
    DEFAULT_ATTRIBUTES = %i[
      id processed_html user_id ancestry deleted hidden_by_commentable_user created_at
    ].freeze

    def self.for_api(commentable, attributes: DEFAULT_ATTRIBUTES, page: nil, per_page: 50)
      tree = commentable.comments
        .includes(user: :profile)
        .select(attributes)
        .arrange(order: "id")
      # paginating only if page is passed
      tree = Kaminari.paginate_array(tree.to_a).page(page).per(per_page).to_h if page.to_i.positive?
      tree
    end
  end
end
