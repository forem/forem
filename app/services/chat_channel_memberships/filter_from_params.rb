module ChatChannelMemberships
  class FilterFromParams
    ATTRIBUTES = %i[
    ].freeze
    private_constant :ATTRIBUTES

    DEFAULT_PER_PAGE = 30
    private_constant :DEFAULT_PER_PAGE

    MAX_PER_PAGE = 60 # to avoid querying too many items, we set a maximum amount for a page
    private_constant :MAX_PER_PAGE

    def self.call(user_ids: [], page: 0, per_page: DEFAULT_PER_PAGE)
      new(user_ids: user_ids, page: page, per_page: per_page).call
    end

    def initialize(user_ids: [], page: 0, per_page: DEFAULT_PER_PAGE)
      @user_ids = user_ids
      @page = page
      @per_page = per_page
    end

    def call
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ChatChannelMembership
        .includes(:chat_channel, :user)
        .where(user_id: user_id, status: %w[active joining_request])
        .select(*ATTRIBUTES)
        .order("chat_channel.last_message_at": :desc)

      results = relation.page(page).per(per_page)
      serialize(results)
    end

    private

    def serialize(results)
      ChatChannelMembership::FilterResultSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
  end
end
