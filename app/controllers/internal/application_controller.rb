class Internal::ApplicationController < ApplicationController
  before_action :authorize_admin
  after_action :verify_authorized

  private

  def authorization_resource
    self.class.name.demodulize.sub("Controller", "").singularize.constantize
  end

  def authorize_admin
    authorize(authorization_resource, :access?, policy_class: InternalPolicy)
  end
end
