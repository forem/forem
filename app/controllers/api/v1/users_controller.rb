module Api
  module V1
    class UsersController < ApiController
      include Api::UsersController

      prepend_before_action :authenticate_with_delegated_access!, only: :me

      before_action :authenticate_with_api_key!, only: %i[me search suspend unpublish]
    end
  end
end
