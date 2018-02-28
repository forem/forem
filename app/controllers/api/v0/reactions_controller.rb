module Api
  module V0
    class ReactionsController < ApplicationController
      skip_before_action :verify_authenticity_token
      def create
        @user = valid_user
        unless @user
          render json: { message: "invalid_user" }, :status => 422
          return
        end
        Rails.cache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
        @reaction = Reaction.create(
          user_id: @user.id,
          reactable_id: params[:reactable_id],
          reactable_type: params[:reactable_type],
          category: params[:category] || "like",
        )
        render json: { reaction: @reaction.to_json }
      end

      private

      def valid_user
        user = User.find_by_secret(params[:key])
        user = nil if !user.has_role?(:super_admin)
        user
      end
    end
  end
end
