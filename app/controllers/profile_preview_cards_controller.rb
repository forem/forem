class ProfilePreviewCardsController < ApplicationController
  layout false

  def show
    @user = User.find(params[:id])
  end
end
