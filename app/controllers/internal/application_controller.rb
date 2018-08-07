class Internal::ApplicationController < ApplicationController
  before_action :authorize_admin

  private

  def authorize_admin
    authorize :admin, :show?
  end
end
