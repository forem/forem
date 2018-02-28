# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_filters.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    skip_before_action :verify_authenticity_token
    include EnforceAdmin
    before_action :authenticate_admin

    def authenticate_admin
      unless current_user_is_admin?
        authenticate_or_request_with_http_basic do |username, password|
          username == ENV["APP_NAME"] && password == ENV["APP_PASSWORD"]
        end
      end
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
    def order
      @_order ||= Administrate::Order.new(params[:order] || "id",params[:direction] || "desc")
    end

  end
end
