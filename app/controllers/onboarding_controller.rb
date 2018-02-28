class OnboardingController < ApplicationController

  def index
    if Rails.env.test?
      redirect_to "/"
    elsif current_user.email.blank? && current_user.unconfirmed_email.blank?
      basic_info
    else
      redirect_to "/settings"
    end
  end

  def basic_info
    @user = current_user
    render :basic_info
  end
end
