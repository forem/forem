class EventSignupsController < ApplicationController
  before_action :authenticate_user!, except: %i[status]
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
    rescue ActiveRecord::RecordInvalid => e
      if e.record.errors.details[:user_id].any? { |d| d[:error] == :taken }
        # Treat concurrent duplicate validation failure as success
        flash[:notice] = "You've successfully signed up for this event!"
      else
        flash[:alert] = "Something went wrong. Please try again."
      end
    end

    respond_to do |format|
      format.html { redirect_to event_path(@event.event_name_slug, @event.event_variation_slug) }
      format.json { render json: { signed_up: true, button_text: @event.signup_button_text(signed_up: true) } }
    end
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

    respond_to do |format|
      format.html { redirect_to event_path(@event.event_name_slug, @event.event_variation_slug) }
      format.json { render json: { signed_up: false, button_text: @event.signup_button_text(signed_up: false) } }
    end
  end

  def status
    authorize :event_signup, :status?
    signed_up = current_user ? current_user.event_signups.exists?(event: @event) : false
    render json: {
      signed_up: signed_up,
      button_text: @event.signup_button_text(signed_up: signed_up)
    }
  end

  private

  def set_event
    @event = Event.find_by!(
      event_name_slug: params[:event_name_slug],
      event_variation_slug: params[:event_variation_slug]
    )
  end
end
