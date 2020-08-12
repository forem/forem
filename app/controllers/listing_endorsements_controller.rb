class ListingEndorsementsController < ApplicationController
  before_action :raise_suspended, only: %i[create update]
  before_action :authenticate_user!, only: %i[update]
  after_action :verify_authorized, only: %i[update]

  def create
    @endorsement = ListingEndorsement.create(content: params[:content], user_id: current_user.id, classified_listing_id: params[:classified_listing_id])
    @endorsement.save

    Notification.send_new_endorsement_notifications_without_delay(@endorsement)
  end

  def update
    @endorsement = ListingEndorsement.find(params[:id])
    return unless @endorsement

    puts "fffffffffffffffffffffffffffffffffggggggggggggggggggggggggggghhhhhhhhhhhhhhhhhh"
    puts params

    @endorsement = @endorsement.update(approved: true) unless @endorsement.approved
    
    puts @endorsement

    if @endorsement.save
      redirect_back(fallback_location: root_path)
    else
      redirect_to root_path
    end
  end
end
