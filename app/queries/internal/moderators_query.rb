module Internal
  class ModeratorsQuery
    DEFAULT_OPTIONS = {
      state: :trusted
    }.with_indifferent_access.freeze

    def self.call(options: {})
      options = DEFAULT_OPTIONS.merge(options)
      state, search = options.values_at(:state, :search)

      formatted_params = if state.to_s == "potential"
                           { exclude_roles: ["trusted"], sort_by: "comments_count", sort_direction: "desc" }
                         else
                           { roles: [state] }
                         end

      formatted_params = formatted_params.merge(name_fields: search) if search.presence
      results = Search::User.search_documents(params: formatted_params.merge(options.slice(:page, :per_page)))
      user_ids = results.map { |doc| doc["id"] }

      Kaminari.paginate_array(User.find(user_ids), total_count: results.first&.dig("total"))
    end
  end
end
