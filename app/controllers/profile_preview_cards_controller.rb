class ProfilePreviewCardsController < ApplicationController
  layout false

  def show
    @user = User.includes(:profile, :setting).find(params[:id])
  end
end
