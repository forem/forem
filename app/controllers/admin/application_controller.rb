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
    after_action :moderator_audit

    def order
      @order ||= Administrate::Order.new(params[:order] || "id", params[:direction] || "desc")
    end

    def valid_request_origin?
      # Temp monkey patch. Since we use https at the edge via fastly I think our protocol expectations
      # are out of wack.
      raise InvalidAuthenticityToken, NULL_ORIGIN_MESSAGE if request.origin == "null"

      request.origin.nil? || request.origin.gsub("https", "http") == request.base_url.gsub("https", "http")
    end

    private

    def authorize_admin
      authorize :admin, :show?
    end

    def moderator_audit
      payload = {
        user: {
          id: current_user.id,
          roles: current_user.roles&.pluck(:name)
        },
        action: {
          method: request.method,
          path: request.original_fullpath
        }
      }

      Moderator::Audit::Notification.new(payload).instrument
    end
  end
end
