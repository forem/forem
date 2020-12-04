class ErrorsController < ApplicationController
  # HTTP 404 - Not Found - https://httpstatuses.com/400
  def not_found
    render status: :not_found
  end

  # HTTP 422 - Unprocessable Entity - https://httpstatuses.com/422
  def unprocessable_entity
    render status: :unprocessable_entity
  end

  # HTTP 500 - Internal Server Error - https://httpstatuses.com/500
  def internal_server_error
    render status: :internal_server_error
  end

  # HTTP 503 - Service Unavailable - https://httpstatuses.com/503
  def service_unavailable
    render status: :service_unavailable
  end
end
