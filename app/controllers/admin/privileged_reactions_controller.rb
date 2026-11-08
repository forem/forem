module Admin
  class PrivilegedReactionsController < Admin::ApplicationController
    layout "admin"

    REACTABLE_SCOPES = {
      "Article" => -> { Article.select(:id, :title, :path) },
      "Comment" => -> { Comment.select(:id, :user_id) },
      "User" => -> { User.select(:id, :username) }
    }.freeze

    # Lists privileged reactions with optional username and category filtering.
    def index
      base_scope = Reaction.privileged_category.order(created_at: :desc)
      @q = base_scope.ransack(params[:q])

      ransack_params = params[:q].respond_to?(:except) ? params[:q].except(:user_username_cont) : params[:q]
      relation = base_scope.ransack(ransack_params).result
      username_filter = params.dig(:q, :user_username_cont).to_s.strip
      if username_filter.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(username_filter)}%"
        relation = relation.where(
          "reactions.user_id = ANY(ARRAY(SELECT users.id FROM users WHERE users.username ILIKE ?))",
          pattern,
        )
      end

      @privileged_reactions = relation.page(params[:page] || 1).per(25).without_count
      preload_privileged_reaction_associations(@privileged_reactions)
    end

    private

    # Batch-preloads reaction authors, polymorphic reactables with minimal columns,
    # and comment authors to avoid N+1 queries and large text column hydration.
    def preload_privileged_reaction_associations(reactions)
      records = reactions.to_a
      return if records.empty?

      user_scope = User.select(:id, :username)
      ActiveRecord::Associations::Preloader.new(records: records, associations: :user, scope: user_scope).call

      records.group_by(&:reactable_type).each do |type, typed_reactions|
        scope = REACTABLE_SCOPES[type]&.call
        ActiveRecord::Associations::Preloader.new(records: typed_reactions, associations: :reactable, scope: scope).call
      end

      comments = records.filter_map { |r| r.reactable if r.reactable_type == "Comment" }
      return if comments.empty?

      ActiveRecord::Associations::Preloader.new(records: comments, associations: :user, scope: user_scope).call
    end
  end
end
