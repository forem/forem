module Admin
  class EventsController < Admin::ApplicationController
    before_action :set_event, only: %i[show edit update destroy]

    def index
      @events = Event.order(created_at: :desc)
    end

    def show
      @event_signups = @event.event_signups.includes(:user).order(created_at: :desc).page(params[:page]).per(50)
    end

    def new
      fork_id = params[:fork_from_id] || params[:fork_from] || params[:fork_id]
      if fork_id.present?
        original_event = Event.find(fork_id)
        @event = original_event.dup
        @event.tag_list = original_event.tag_list
      else
        @event = Event.new
      end
    end

    def fork
      redirect_to new_admin_event_path(fork_from_id: params[:id])
    end

    def edit; end

    def create
      @event = Event.new(event_params)
      if @event.save
        redirect_to admin_events_path, notice: "Event created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @event.update(event_params)
        redirect_to admin_events_path, notice: "Event updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: "Event destroyed successfully."
    end

    def end_broadcast
      @event = Event.find(params[:id])

      if @event.update(broadcast_ended_at: Time.current)
        Events::ManageBroadcastBillboardsWorker.perform_async
        redirect_to admin_event_path(@event),
                    notice: "Broadcast manually ended. Billboards are being deactivated locally."
      else
        redirect_to admin_event_path(@event), alert: "Failed to end broadcast."
      end
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :title,
        :event_name_slug,
        :event_variation_slug,
        :description,
        :primary_stream_url,
        :published,
        :elevated,
        :start_time,
        :end_time,
        :type_of,
        :broadcast_config,
        :manual_broadcast_end,
        :user_id,
        :organization_id,
        :tag_list,
        :page_id,
        :delegate_to_page,
        :cover_image,
        :remove_cover_image,
        :bg_color_hex,
        data: {},
      )
    end
  end
end
