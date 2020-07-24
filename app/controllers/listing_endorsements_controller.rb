class ListingEndorsementsController < ApplicationController
  before_action :raise_suspended, only: %i[create] # update
  # before_action :authenticate_user!, only: %i[edit update]
  # after_action :verify_authorized, only: %i[edit update]

  def create
    @endorsement = ListingEndorsement.create(content: params[:content], user_id: current_user.id, classified_listing_id: params[:classified_listing_id])
    @endorsement.save
  end

  # def edit

  # end

  # def update

  # end
end
