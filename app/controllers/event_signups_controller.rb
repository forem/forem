class EventSignupsController < ApplicationController
  before_action :authenticate_user!, except: %i[status]
  before_action :set_event
  before_action :set_no_cache_header, only: %i[status create destroy]

  def create
    signup = current_user.event_signups.find_or_initialize_by(event: @event)
    authorize signup

    success = true
    notice = @event.challenge? ? "You've successfully signed up for this challenge!" : "You've successfully signed up for this event!"

    begin
      signup.save!
      flash[:notice] = notice
    rescue ActiveRecord::RecordNotUnique
      # Treat concurrent duplicate signup as success
      flash[:notice] = notice
    rescue ActiveRecord::RecordInvalid => e
      if e.record.errors.details[:user_id].any? { |d| d[:error] == :taken }
        # Treat concurrent duplicate validation failure as success
        flash[:notice] = notice
      else
        flash[:alert] = "Something went wrong. Please try again."
        success = false
      end
    end

    respond_to do |format|
      format.html { redirect_to event_path(@event.event_name_slug, @event.event_variation_slug) }
      format.json do
        if success
          render json: { signed_up: true, button_text: @event.signup_button_text(signed_up: true) }
        else
          render json: { signed_up: false, button_text: @event.signup_button_text(signed_up: false), error: flash[:alert] }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    signup = current_user.event_signups.find_by(event: @event)
    success = true
    notice = @event.challenge? ? "You've successfully unregistered from this challenge." : "You've removed your interest in this event."

    if signup
      authorize signup
      if signup.destroy
        flash[:notice] = notice
      else
        flash[:alert] = "Something went wrong. Please try again."
        success = false
      end
    else
      skip_authorization
    end

    respond_to do |format|
      format.html { redirect_to event_path(@event.event_name_slug, @event.event_variation_slug) }
      format.json do
        if success
          render json: { signed_up: false, button_text: @event.signup_button_text(signed_up: false) }
        else
          render json: { signed_up: true, button_text: @event.signup_button_text(signed_up: true), error: flash[:alert] }, status: :unprocessable_entity
        end
      end
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
