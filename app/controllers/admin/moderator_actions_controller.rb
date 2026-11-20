module Admin
  class ModeratorActionsController < Admin::ApplicationController
    layout "admin"

    # Lists moderator audit logs with optional username search, indexed primary-key ordering,
    # narrow column selection, and countless pagination.
    def index
      base_scope = AuditLog
        .select(:id, :user_id, :data, :created_at)
        .where(category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
      @q = base_scope.ransack(params[:q])
      @q.sorts = "created_at desc" if @q.sorts.empty?

      ransack_params = params[:q].respond_to?(:except) ? params[:q].except(:user_username_cont, :s) : params[:q]
      relation = apply_sort_order(base_scope.ransack(ransack_params).result)
      username_filter = params.dig(:q, :user_username_cont).to_s.strip
      if username_filter.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(username_filter)}%"
        relation = relation.where(
          "audit_logs.user_id = ANY(ARRAY(SELECT users.id FROM users WHERE users.username ILIKE ?))",
          pattern,
        )
      end

      @moderator_actions = relation.page(params[:page] || 1).per(25).without_count
      preload_users(@moderator_actions)
    end

    private

    def apply_sort_order(relation)
      sort_param = params.dig(:q, :s).to_s.strip.downcase
      return relation.order(id: :asc) if sort_param == "created_at asc"

      relation.order(id: :desc)
    end

    def preload_users(actions)
      records = actions.to_a
      return if records.empty?

      ActiveRecord::Associations::Preloader.new(
        records: records,
        associations: :user,
        scope: User.select(:id, :username),
      ).call
    end
  end
end
