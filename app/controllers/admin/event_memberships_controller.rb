module Admin
  class EventMembershipsController < Admin::ApplicationController
    before_action :set_event
    before_action :set_membership, only: %i[update destroy reorder]

    def create
      child_event = Event.find_by(id: membership_params[:child_event_id])
      if child_event.nil?
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    alert: I18n.t("views.admin.event_memberships.child_not_found")
        return
      end

      position = membership_params[:position].presence ||
        ((@event.child_event_memberships.maximum(:position) || -1) + 1)

      membership = @event.child_event_memberships.build(
        child_event: child_event,
        position: position,
        role: membership_params[:role],
        featured: ActiveModel::Type::Boolean.new.cast(membership_params[:featured]) || false,
      )

      if membership.save
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    notice: I18n.t("views.admin.event_memberships.created", title: child_event.title)
      else
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    alert: membership.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotUnique
      redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                  alert: I18n.t("models.event_membership.already_member")
    end

    def update
      if @membership.update(membership_update_params)
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    notice: I18n.t("views.admin.event_memberships.updated")
      else
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    alert: @membership.errors.full_messages.to_sentence
      end
    end

    def destroy
      child_title = @membership.child_event&.title
      return_to = params[:return_to_event_id].present? ? Event.find_by(id: params[:return_to_event_id]) : @event
      @membership.destroy!
      redirect_to admin_event_path(return_to || @event, anchor: "event-hierarchy"),
                  notice: I18n.t("views.admin.event_memberships.destroyed", title: child_title)
    end

    def reorder
      direction = params[:direction].to_s
      if %w[up down].include?(direction) && reorder_membership(direction)
        redirect_to admin_event_path(@event, anchor: "event-hierarchy"),
                    notice: I18n.t("views.admin.event_memberships.reordered")
      else
        redirect_to admin_event_path(@event, anchor: "event-hierarchy")
      end
    end

    protected

    def authorization_resource
      Event
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    end

    def set_membership
      @membership = @event.child_event_memberships.includes(:child_event).find(params[:id])
    end

    def membership_params
      params.require(:event_membership).permit(:child_event_id, :position, :role, :featured)
    end

    def membership_update_params
      params.require(:event_membership).permit(:position, :role, :featured)
    end

    def reorder_membership(direction)
      EventMembership.transaction do
        ordered = @event.child_event_memberships.ordered.lock.to_a
        index = ordered.index { |item| item.id == @membership.id }
        next false unless index

        target_index = direction == "up" ? index - 1 : index + 1
        next false if target_index.negative? || target_index >= ordered.length

        ordered[index], ordered[target_index] = ordered[target_index], ordered[index]
        ordered.each_with_index do |item, pos|
          item.update_column(:position, pos) if item.position != pos
        end
        ActiveRecord.after_all_transactions_commit { @event.purge_hierarchy_edge_cache! }
        true
      end
    end
  end
end
