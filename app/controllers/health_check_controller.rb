class HealthCheckController < ApplicationController
  def ping
    render json: { message: "App is up!" }, status: :ok
  end

  def search_ping
    if Search::Client.ping
      render json: { message: "Search ping succeeded!" }, status: :ok
    else
      render json: { message: "Search ping failed!" }, status: :internal_server_error
    end
  end

  def database_ping
    if ActiveRecord::Base.connected?
      render json: { message: "Database connected" }, status: :ok
    else
      render json: { message: "Database NOT connected!" }, status: :internal_server_error
    end
  end
end
