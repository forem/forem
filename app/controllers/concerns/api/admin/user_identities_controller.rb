module Api
  module Admin
    module UserIdentitiesController
      extend ActiveSupport::Concern

      def index
        target = User.find(params[:user_id])
        @identities = target.identities.order(created_at: :asc)
      end
    end
  end
end
