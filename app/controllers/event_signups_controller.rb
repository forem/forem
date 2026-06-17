class EventSignupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    signup = current_user.event_signups.find_or_initialize_by(event: @event)
    authorize signup

    begin
      signup.save!
      flash[:notice] = "You've successfully signed up for this event!"
    rescue ActiveRecord::RecordNotUnique
      # Treat concurrent duplicate signup as success
      flash[:notice] = "You've successfully signed up for this event!"
    rescue ActiveRecord::RecordInvalid
      flash[:alert] = "Something went wrong. Please try again."
    end
    redirect_to event_path(@event.event_name_slug, @event.event_variation_slug)
  end

  def destroy
    signup = current_user.event_signups.find_by(event: @event)
    if signup
      authorize signup
      signup.destroy
      flash[:notice] = "You've removed your interest in this event."
    else
      skip_authorization
    end
    redirect_to event_path(@event.event_name_slug, @event.event_variation_slug)
  end

  private

  def set_event
    @event = Event.find_by!(
      event_name_slug: params[:event_name_slug],
      event_variation_slug: params[:event_variation_slug]
    )
  end
end
