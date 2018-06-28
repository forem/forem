# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_filters.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Pundit
    before_action :authorize_admin

    def order
      @_order ||= Administrate::Order.new(params[:order] || "id",params[:direction] || "desc")
    end

    private

    def authorize_admin
      authorize :admin, :show?
    end
  end
end
