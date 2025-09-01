module Api
  module V1
    class BadgesController < ApiController
      include Api::BadgesController

      before_action :authenticate!
      before_action :require_admin
    end
  end
end