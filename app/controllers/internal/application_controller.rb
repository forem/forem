class Internal::ApplicationController < ApplicationController
  before_action :authorize_admin
  after_action :verify_authorized

  private

  def authorize_admin
    authorize :admin, :minimal?
  end
end
