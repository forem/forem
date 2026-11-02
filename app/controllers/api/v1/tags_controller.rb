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
      before_action :authenticate_with_api_key!, only: %i[update]
      before_action :authorize_admin, only: %i[update]

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

      private

      def authorize_admin
        authorize Tag, :access?, policy_class: InternalPolicy
      end

      def tag_params
        params.permit(UPDATE_PARAMS)
      end
    end
  end
end
