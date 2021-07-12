class ProfilePreviewCardController < ApplicationController
  layout false

  def show
    @actor = User.find_by(id: params[:id])
  end
end
