module Api
  module V1
    class TagsController < ApiController
      include Api::TagsController

      # A subset of Admin::TagsController::ALLOWED_PARAMS: plain attributes that
      # need no extra side effects beyond the Tag model's own callbacks.
      UPDATE_PARAMS = %i[
        pretty_name short_summary wiki_body_markdown supported
        bg_color_hex text_color_hex context_note_instructions
      ].freeze

      before_action :set_cache_control_headers, only: %i[index supported]
      before_action :authenticate_with_api_key!, only: %i[create update add_moderator remove_moderator]
      before_action :authorize_admin, only: %i[create update add_moderator remove_moderator]
      before_action :set_tag_and_moderator, only: %i[add_moderator remove_moderator]

      def create
        @tag = Tag.new(params.permit(:name, *UPDATE_PARAMS))
        # Tags created from posts are lowercased (ActsAsTaggableOn.force_lowercase); match that here.
        @tag.name = @tag.name.downcase if @tag.name

        if save_tag
          Audit::Logger.log(:admin_api, @user, { "action" => "api_tag_create", "tag_id" => @tag.id })
          render :update, status: :created
        else
          error = { error: @tag.errors.full_messages.to_sentence, status: 422 }
          error[:id] = Tag.find_by!(name: @tag.name).id if @tag.errors.of_kind?(:name, :taken)
          render json: error, status: :unprocessable_entity
        end
      end

      def update
        @tag = Tag.find(params[:id])
        @tag.update!(tag_params)

        payload = {
          "action" => "api_tag_update",
          "tag_id" => @tag.id,
          "tag_name" => @tag.name,
          "params" => tag_params.to_h
        }
        Audit::Logger.log(:admin_api, @user, payload)
      end

      def add_moderator
        if moderator_of_tag?
          return error_unprocessable_entity("#{@moderator.username} is already a moderator of this tag")
        end

        result = TagModerators::Add.call(@moderator.id, @tag.id)
        return error_unprocessable_entity(result.errors) unless result.success?

        log_moderator_change("api_tag_moderator_add")
        render json: moderator_json, status: :created
      end

      def remove_moderator
        unless moderator_of_tag?
          return error_unprocessable_entity("#{@moderator.username} is not a moderator of this tag")
        end

        TagModerators::Remove.call(@moderator, @tag)
        log_moderator_change("api_tag_moderator_remove")
        render json: moderator_json
      end

      private

      def set_tag_and_moderator
        @tag = Tag.find(params[:id])
        @moderator = if params[:user_id].present?
                       User.find(params[:user_id])
                     else
                       User.find_by!(username: params.require(:username))
                     end
      end

      def moderator_of_tag?
        @moderator.roles.exists?(name: "tag_moderator", resource_type: "Tag", resource_id: @tag.id)
      end

      def log_moderator_change(action)
        Audit::Logger.log(:admin_api, @user, { "action" => action, "tag_id" => @tag.id, "user_id" => @moderator.id })
      end

      def moderator_json
        { tag_id: @tag.id, tag_name: @tag.name, user_id: @moderator.id, username: @moderator.username }
      end

      def save_tag
        @tag.save
      rescue ActiveRecord::RecordNotUnique
        raise unless Tag.exists?(name: @tag.name)

        @tag.errors.add(:name, :taken)
        false
      end

      def authorize_admin
        authorize Tag, :access?, policy_class: InternalPolicy
      end

      def tag_params
        params.permit(UPDATE_PARAMS)
      end
    end
  end
end
