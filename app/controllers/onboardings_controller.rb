class OnboardingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cache_control_headers, only: %i[show]

  def show
    set_surrogate_key_header "onboarding-slideshow"
  end
end
