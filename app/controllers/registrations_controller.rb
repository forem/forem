class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []
  # No authorization required for public registration route

  def new
    if user_signed_in?
      redirect_to "/dashboard?signed-in-already&t=#{Time.now.to_i}"
      return
    end
    super
  end

  private

  def core_pages?
    true
  end
end
