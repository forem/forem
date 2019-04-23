class Api::V0::ApiController < ApplicationController
  def cors_set_access_control_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization, Token"
    headers["Access-Control-Max-Age"] = "1728000"
  end

  def cors_preflight_check
    return unless request.method == "OPTIONS"

    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-Prototype-Version, Token"
    headers["Access-Control-Max-Age"] = "1728000"

    render text: "", content_type: "text/plain"
  end

  def unprocessable_entity(exception)
    render json: { error: exception, status: 422 },
           status: :unprocessable_entity
  end

  def not_authorized
    render json: { error: "Not authorized", status: 401 },
           status: :unauthorized
  end
end
