module Api
  module V0
    class EventMembershipsController < ApiController
      skip_csrf_unless_cookie_authenticated only: %i[create update destroy]
      before_action :authenticate!, except: %i[index]
      before_action :evaluate_authentication, only: %i[index]
      before_action :set_event
      before_action :set_membership, only: %i[update destroy]

      def index
        include_drafts = admin_event_access?
        unless @event.published? || include_drafts
          return render json: { error: "Event not found" }, status: :not_found
        end

        render json: Events::ApiSerializer.serialize_memberships_payload(@event, include_drafts: include_drafts)
      end

      def create
        authorize Event
        attrs = membership_params
        child_event = Event.find_by(id: attrs[:child_event_id])
        if child_event.nil?
          return render json: { error: ["Child event not found"] }, status: :unprocessable_entity
        end

        position = attrs[:position].presence || ((@event.child_event_memberships.maximum(:position) || -1) + 1)
        membership = @event.child_event_memberships.build(
          child_event: child_event,
          position: position,
          role: attrs[:role],
          featured: attrs.key?(:featured) ? attrs[:featured] : false,
        )

        if membership.save
          Audit::Logger.log(
            :admin_api,
            @user,
            {
              "action" => "api_event_membership_create",
              "event_id" => @event.id,
              "event_membership_id" => membership.id,
              "child_event_id" => membership.child_event_id
            },
          )
          render json: Events::ApiSerializer.serialize_membership(membership), status: :created
        else
          render json: { error: membership.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotUnique
        render json: { error: [I18n.t("models.event_membership.already_member")] }, status: :unprocessable_entity
      end

      def update
        authorize Event
        if @membership.update(membership_update_params)
          Audit::Logger.log(
            :admin_api,
            @user,
            {
              "action" => "api_event_membership_update",
              "event_id" => @event.id,
              "event_membership_id" => @membership.id,
              "child_event_id" => @membership.child_event_id
            },
          )
          render json: Events::ApiSerializer.serialize_membership(@membership)
        else
          render json: { error: @membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize Event
        child_event_id = @membership.child_event_id
        membership_id = @membership.id
        @membership.destroy
        if @membership.destroyed?
          Audit::Logger.log(
            :admin_api,
            @user,
            {
              "action" => "api_event_membership_destroy",
              "event_id" => @event.id,
              "event_membership_id" => membership_id,
              "child_event_id" => child_event_id
            },
          )
        end
        head :no_content
      end

      private

      def admin_event_access?
        @user&.administrative_access_to?(resource: Event) || false
      end

      def evaluate_authentication
        return unless request.headers["api-key"]

        authenticate!
      end

      def set_event
        @event = Event.find(params[:event_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def set_membership
        @membership = @event.child_event_memberships.includes(:child_event).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event membership not found" }, status: :not_found
      end

      def raw_membership_params
        params[:event_membership].is_a?(ActionController::Parameters) ? params.require(:event_membership) : params
      end

      def membership_params
        raw_membership_params.permit(:child_event_id, :position, :role, :featured)
      end

      def membership_update_params
        raw_membership_params.permit(:position, :role, :featured)
      end
    end
  end
end
