module Api
  module FollowsController
    extend ActiveSupport::Concern

    def create
      # API authentication might set current_user or might just set @user
      active_user = current_user || @user

      user_ids.each do |user_id|
        Users::FollowWorker.perform_async(active_user.id, user_id, "User")
      end

      org_ids.each do |org_id|
        Users::FollowWorker.perform_async(active_user.id, org_id, "Organization")
      end

      render json: {
        outcome: I18n.t("api.v0.follows_controller.followed",
                        count: user_ids.size + org_ids.size)
      }
    end

    def tags
      if native_followed_tags_serializable? && (json_body = serialize_followed_tags_natively)
        render json: json_body
        return
      end

      @follows = @user.follows_by_type("ActsAsTaggableOn::Tag")
        .select(%i[id followable_id followable_type points])
        .includes(:followable)
        .order(points: :desc)
    end

    private

    def native_followed_tags_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def serialize_followed_tags_natively
      # `follows_by_type` adds `includes(:followable)`; drop it so the polymorphic
      # association is not eager loaded alongside the explicit `tags` join.
      rows = @user.follows_by_type("ActsAsTaggableOn::Tag")
        .except(:includes)
        .joins("INNER JOIN tags ON tags.id = follows.followable_id")
        .order(points: :desc)
        .pluck("tags.id", "tags.name", "follows.points")
      return "[]" if rows.empty?

      ForemNative.serialize_api_followed_tags_json(
        rows.flatten(1),
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end

    # The strange params situation here is mostly due to a bug in the way
    # rswag processes array-type params that appear in a query-string.
    # Also, Rails' strong parameters does not work well with arrays-of-objects.
    # So, in order to include this end-point in the swagger/open-api
    # documentation, while maintaining compatibility with the existing
    # infrastructure, we need to accept two kinds of inputs here -
    # in one case, we receive a list of integer IDs,
    # in the other case, we receive an array of objects, like {id: 123}
    def user_ids
      @user_ids ||= permitted_params[:user_ids].presence
      @user_ids ||= params[:users].pluck("id") if params[:users].present?
      @user_ids ||= []
    end

    def org_ids
      @org_ids ||= permitted_params[:organization_ids].presence
      @org_ids ||= params[:organizations].pluck("id") if params[:organizations].present?
      @org_ids ||= []
    end

    def permitted_params
      params.permit(user_ids: [], organization_ids: [])
    end
  end
end
