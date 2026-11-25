module Api
  module V0
    class EventsController < ApiController
      skip_csrf_unless_cookie_authenticated only: %i[create update destroy]
      before_action :authenticate!, except: %i[index show]
      before_action :set_event, only: %i[show update destroy]

      # Authentication is optional for index and show
      # We manually attempt to authenticate to populate current_user if the token is present
      before_action :evaluate_authentication, only: %i[index show]

      def index
        include_drafts = admin_event_access?
        @events = Event.all
        @events = @events.published unless include_drafts

        if params[:type_of].present? && Event.type_ofs.key?(params[:type_of])
          @events = @events.where(type_of: params[:type_of])
        end

        @events = apply_hierarchy_filters(@events, include_drafts: include_drafts)
        return if performed?

        include_hierarchy = ActiveModel::Type::Boolean.new.cast(params[:include_hierarchy] || params[:members])

        # Serializing tag_list reads each event's taggings (acts-as-taggable-on's
        # custom context check), so preload them in one query instead of one per event.
        ordered_events = @events.includes(:taggings).order(created_at: :desc)
        render json: Events::ApiSerializer.serialize_collection(
          ordered_events,
          include_drafts: include_drafts,
          include_hierarchy: include_hierarchy,
        )
      end

      def show
        include_drafts = admin_event_access?
        unless @event.published? || include_drafts
          return render json: { error: "Event not found" }, status: :not_found
        end

        render json: Events::ApiSerializer.serialize_single(@event, include_drafts: include_drafts)
      end

      def create
        authorize Event
        parent_ids, child_entries = extract_hierarchy_params
        @event = Event.new(event_params.except(:user_id))
        @event.user_id = @user.id if @event.user_id.blank?

        saved = save_event_with_memberships(parent_ids: parent_ids, child_entries: child_entries)
        if saved
          Audit::Logger.log(:admin_api, @user, { "action" => "api_event_create", "event_id" => @event.id })
          render json: Events::ApiSerializer.serialize_single(@event, include_drafts: true), status: :created
        else
          render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @event
        parent_ids, child_entries = extract_hierarchy_params
        # Prevents arbitrary user hijacking via parameters:
        @event.assign_attributes(event_params.except(:user_id))

        saved = save_event_with_memberships(parent_ids: parent_ids, child_entries: child_entries)
        if saved
          Audit::Logger.log(:admin_api, @user, { "action" => "api_event_update", "event_id" => @event.id })
          render json: Events::ApiSerializer.serialize_single(@event, include_drafts: true)
        else
          render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @event
        @event.destroy
        if @event.destroyed?
          Audit::Logger.log(:admin_api, @user, { "action" => "api_event_destroy", "event_id" => @event.id })
        end
        head :no_content
      end

      private

      def admin_event_access?
        @user&.administrative_access_to?(resource: Event) || false
      end

      def apply_hierarchy_filters(scope, include_drafts:)
        if params[:parent_event_id].present?
          parent = Event.find_by(id: params[:parent_event_id])
          if parent.nil? || (!parent.published? && !include_drafts)
            render json: []
            return scope.none
          end

          scope = scope.joins(:parent_event_memberships)
            .where(event_memberships: { parent_event_id: parent.id })
        end

        if params[:child_event_id].present?
          child = Event.find_by(id: params[:child_event_id])
          if child.nil? || (!child.published? && !include_drafts)
            render json: []
            return scope.none
          end

          scope = scope.joins(:child_event_memberships)
            .where(event_memberships: { child_event_id: child.id })
        end

        if params[:scope] == "top_level" || ActiveModel::Type::Boolean.new.cast(params[:top_level])
          scope = include_drafts ? scope.top_level : scope.top_level_published
        end

        scope
      end

      def extract_hierarchy_params
        event_hash = params[:event]
        return [nil, nil] unless event_hash.is_a?(ActionController::Parameters)

        parent_ids = event_hash.key?(:parent_event_ids) ? Array(event_hash[:parent_event_ids]) : nil
        child_entries = if event_hash.key?(:sub_event_memberships)
                          Array(event_hash[:sub_event_memberships]).map do |entry|
                            if entry.is_a?(ActionController::Parameters)
                              entry.permit(:child_event_id, :event_id, :id, :position, :role, :featured).to_h
                            else
                              entry
                            end
                          end
                        elsif event_hash.key?(:sub_event_ids)
                          Array(event_hash[:sub_event_ids])
                        end
        [parent_ids, child_entries]
      end

      def save_event_with_memberships(parent_ids:, child_entries:)
        success = false
        Event.transaction do
          unless @event.save
            raise ActiveRecord::Rollback
          end

          if !parent_ids.nil? && !Events::SyncMemberships.sync_parents(@event, parent_ids)
            raise ActiveRecord::Rollback
          end

          if !child_entries.nil? && !Events::SyncMemberships.sync_children(@event, child_entries)
            raise ActiveRecord::Rollback
          end

          success = true
        end
        success
      end

      def evaluate_authentication
        # Forem's ApiController usually requires valid token if provided, but optional if omitted.
        # This safely tries to log them in if token is sent.
        return unless request.headers["api-key"]

        authenticate!
      end

      def set_event
        @event = Event.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end

      def event_params
        params.require(:event).permit(
          :title,
          :event_name_slug,
          :event_variation_slug,
          :description,
          :body_markdown,
          :full_details,
          :primary_stream_url,
          :published,
          :elevated,
          :allow_articles,
          :broadcast_config,
          :manual_broadcast_end,
          :bg_color_hex,
          :page_id,
          :delegate_to_page,
          :start_time,
          :end_time,
          :type_of,
          :user_id,
          :organization_id,
          :tag_list,
          data: {},
        )
      end
    end
  end
end
