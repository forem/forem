module Api
  module V1
    class FeedbackMessagesController < ApiController
      # This API is designed for authorized admin actions on updating feedback messages
      before_action :authenticate!
      before_action :require_admin

      def update
        feedback_message = FeedbackMessage.find(params[:id])
        result = feedback_message.update(feedback_message_params)
        render json: feedback_message, status: (result ? :ok : :unprocessable_entity)
      end

      private

      def feedback_message_params
        params.require(:feedback_message).permit(:status)
      end

      def require_admin
        authorize :reaction, :api?
      end
    end
  end
end
