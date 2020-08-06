class ListingEndorsementsController < ApplicationController
  before_action :raise_suspended, only: %i[create] # update
  # before_action :authenticate_user!, only: %i[edit update]
  # after_action :verify_authorized, only: %i[edit update]

  def create
    @endorsement = ListingEndorsement.create(content: params[:content], user_id: current_user.id, classified_listing_id: params[:classified_listing_id])
    @endorsement.save

    #k = Article.last.comments.create(body_markdown: "this is a comment to test na2", user_id: 3)

    puts "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbefore the fake test of notification"
    #Notification.send_new_comment_notifications_without_delay(k)
    Notification.send_new_endorsement_notifications_without_delay(@endorsement)
    puts "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaafter the fake notification test"
  end

  # def edit

  # end

  # def update

  # end
end
