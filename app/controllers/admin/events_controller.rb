module Admin
  class EventsController < Admin::ApplicationController
    layout "admin"

    before_action :set_event, only: %i[show edit update destroy]

    def index
      @view_mode = params[:view] == "flat" ? "flat" : "hierarchy"
      @query = params[:q].to_s.strip
      @type_filter = params[:type_of].presence if Event.type_ofs.key?(params[:type_of].to_s)
      @status_filter = %w[published draft].include?(params[:status]) ? params[:status] : nil

      filtered_scope = build_filtered_scope
      is_filtered = @query.present? || @type_filter.present? || @status_filter.present?

      @hierarchy_tree = Events::HierarchyTree.new(
        scope: filtered_scope,
        page: params[:page],
        flat: @view_mode == "flat",
        filtered: is_filtered,
      )
      @events = @hierarchy_tree.roots.map(&:event)
    end

    def show
      @event_signups = @event.event_signups.includes(:user).order(created_at: :desc).page(params[:page]).per(50)
      @child_memberships = @event.child_event_memberships.ordered.includes(:child_event).to_a
      @parent_memberships = @event.parent_event_memberships.ordered.includes(:parent_event).to_a
      @available_sub_events = available_sub_event_candidates(@event)
    end

    def new
      fork_id = params[:fork_from_id] || params[:fork_from] || params[:fork_id]
      if fork_id.present?
        original_event = Event.find(fork_id)
        @event = original_event.dup
        @event.tag_list = original_event.tag_list
        @selected_parent_event_ids = original_event.parent_event_memberships.pluck(:parent_event_id)
      else
        @event = Event.new
        prefill_from_parent_param
      end
      load_parent_event_options
    end

    def fork
      redirect_to new_admin_event_path(fork_from_id: params[:id])
    end

    def edit
      @selected_parent_event_ids = @event.parent_event_memberships.pluck(:parent_event_id)
      load_parent_event_options
    end

    def create
      @event = Event.new(event_params)
      parent_ids = extract_parent_event_ids

      if save_event_with_parents(parent_ids)
        redirect_to admin_events_path, notice: "Event created successfully."
      else
        @selected_parent_event_ids = Array(parent_ids).filter_map { |id| id.to_i if id.present? }
        load_parent_event_options
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @event.assign_attributes(event_params)
      parent_ids = extract_parent_event_ids

      if save_event_with_parents(parent_ids)
        redirect_to admin_events_path, notice: "Event updated successfully."
      else
        @selected_parent_event_ids = if parent_ids.nil?
                                       @event.parent_event_memberships.pluck(:parent_event_id)
                                     else
                                       Array(parent_ids).filter_map { |id| id.to_i if id.present? }
                                     end
        load_parent_event_options
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

    def build_filtered_scope
      scope = Event.all
      scope = scope.where(type_of: @type_filter) if @type_filter.present?
      scope = scope.where(published: @status_filter == "published") if @status_filter.present?

      if @query.present?
        escaped = ActiveRecord::Base.sanitize_sql_like(@query)
        pattern = "%#{escaped}%"
        scope = scope.where(
          "title ILIKE :q OR event_name_slug ILIKE :q OR event_variation_slug ILIKE :q",
          q: pattern,
        )
      end

      scope
    end

    def prefill_from_parent_param
      @selected_parent_event_ids = []
      return if params[:parent_event_id].blank?

      parent = Event.find_by(id: params[:parent_event_id])
      return unless parent

      @initial_parent_event = parent
      @selected_parent_event_ids = [parent.id]
      @event.event_name_slug = parent.event_name_slug
      @event.organization_id = parent.organization_id
      @event.bg_color_hex = parent.bg_color_hex
      @event.start_time = parent.start_time
      @event.end_time = [parent.start_time + 1.hour, parent.end_time].min
      @event.type_of = :live_stream
    end

    def load_parent_event_options
      excluded_ids = @event.persisted? ? [@event.id] + @event.descendant_event_ids : []
      scope = Event.select(:id, :title, :type_of, :start_time, :published).order(start_time: :desc, title: :asc)
      scope = scope.where.not(id: excluded_ids) if excluded_ids.any?
      @available_parent_events = scope.to_a
    end

    def available_sub_event_candidates(event)
      excluded_ids = [event.id] + @child_memberships.map(&:child_event_id) + event.ancestor_event_ids
      Event.select(:id, :title, :type_of, :start_time, :published)
        .where.not(id: excluded_ids)
        .order(start_time: :desc, title: :asc)
        .to_a
    end

    def extract_parent_event_ids
      raw_event = params[:event]
      return unless raw_event.is_a?(ActionController::Parameters) && raw_event.key?(:parent_event_ids)

      Array(raw_event[:parent_event_ids]).compact_blank
    end

    def save_event_with_parents(parent_ids)
      success = false
      Event.transaction do
        raise ActiveRecord::Rollback unless @event.save

        if !parent_ids.nil? && !Events::SyncMemberships.sync_parents(@event, parent_ids)
          raise ActiveRecord::Rollback
        end

        success = true
      end
      success
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
        :banner_image,
        :remove_banner_image,
        :bg_color_hex,
        data: {},
      )
    end
  end
end
