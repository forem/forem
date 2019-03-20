# send notifications about the new reaction
module Notifications
  module Reactions
    class Send
      # receiver - User, Organization
      def initialize(reaction, receiver)
        @reaction = reaction
        @receiver = receiver
      end

      delegate :user_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      def call
        return unless receiver.is_a?(User) || receiver.is_a?(Organization)
        return if reaction.user_id == reaction.reactable.user_id
        return if reaction.points.negative?
        return if receiver.is_a?(User) && reaction.reactable.receive_notifications == false

        reaction_siblings = Reaction.where(reactable_id: reaction.reactable_id, reactable_type: reaction.reactable_type).
          where.not(reactions: { user_id: reaction.reactable.user_id }).
          order("created_at DESC")

        aggregated_reaction_siblings = reaction_siblings.map { |r| { category: r.category, created_at: r.created_at, user: user_data(r.user) } }

        notification_params = {
          notifiable_type: reaction.reactable.class.name,
          notifiable_id: reaction.reactable.id,
          action: "Reaction"
          # user_id or organization_id: receiver.id
        }
        if receiver.is_a?(User)
          notification_params[:user_id] = receiver.id
        elsif receiver.is_a?(Organization)
          notification_params[:organization_id] = receiver.id
        end

        if aggregated_reaction_siblings.size.zero?
          notification = Notification.where(notification_params).delete_all
        else
          recent_reaction = reaction_siblings.first

          json_data = {
            user: user_data(recent_reaction.user),
            reaction: {
              category: recent_reaction.category,
              reactable_type: recent_reaction.reactable_type,
              reactable_id: recent_reaction.reactable_id,
              reactable: {
                path: recent_reaction.reactable.path,
                title: recent_reaction.reactable.title,
                class: {
                  name: recent_reaction.reactable.class.name
                }
              },
              aggregated_siblings: aggregated_reaction_siblings,
              updated_at: recent_reaction.updated_at
            }
          }

          previous_siblings_size = 0
          notification = Notification.find_or_create_by(notification_params)
          previous_siblings_size = notification.json_data["reaction"]["aggregated_siblings"].size if notification.json_data
          notification.json_data = json_data
          notification.notified_at = Time.current
          notification.read = false if json_data[:reaction][:aggregated_siblings].size > previous_siblings_size
          notification.save!
        end
        notification
      end

      private

      attr_reader :reaction, :receiver
    end
  end
end
