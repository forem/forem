class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, :only => []
  def new
    if user_signed_in?
      redirect_to "/dashboard?signed-in-already&t=#{Time.now.to_i}"
      return
    end
    super
  end
end
