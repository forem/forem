# send notifications about the new reaction
module Notifications
  module Reactions
    class Send
      # @param reaction_data [Hash]
      #   * :reactable_id [Integer] - article or comment id
      #   * :reactable_type [String] - "Article" or "Comment"
      #   * :reactable_user_id [Integer] - user id
      # @param receiver [User] or [Organization]
      def initialize(reaction_data, receiver)
        @reaction = reaction_data.is_a?(ReactionData) ? reaction_data : ReactionData.new(reaction_data)
        @receiver = receiver
      end

      delegate :user_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      # @return [OpenStruct, #action, #notification_id]
      def call
        return unless receiver.is_a?(User) || receiver.is_a?(Organization)

        reaction_siblings = Reaction.where(reactable_id: reaction.reactable_id, reactable_type: reaction.reactable_type).
          where.not(reactions: { user_id: reaction.reactable_user_id }).
          preload(:reactable).includes(:user).where.not(users: { id: nil }).
          order("reactions.created_at DESC")

        aggregated_reaction_siblings = reaction_siblings.map { |reaction| { category: reaction.category, created_at: reaction.created_at, user: user_data(reaction.user) } }

        notification_params = {
          notifiable_type: reaction.reactable_type,
          notifiable_id: reaction.reactable_id,
          action: "Reaction"
        }
        if receiver.is_a?(User)
          notification_params[:user_id] = receiver.id
        elsif receiver.is_a?(Organization)
          notification_params[:organization_id] = receiver.id
        end

        if aggregated_reaction_siblings.size.zero?
          Notification.where(notification_params).delete_all
          OpenStruct.new(action: :deleted)
        else
          recent_reaction = reaction_siblings.first

          json_data = reaction_json_data(recent_reaction, aggregated_reaction_siblings)

          previous_siblings_size = 0
          notification = Notification.find_or_initialize_by(notification_params)
          previous_siblings_size = notification.json_data["reaction"]["aggregated_siblings"].size if notification.json_data
          notification.json_data = json_data
          notification.notified_at = Time.current
          notification.read = false if json_data[:reaction][:aggregated_siblings].size > previous_siblings_size

          # temporarily returning validations to prevent creating duplicate notifications
          # notification_id = save_notification(notification)
          notification.save!
          notification_id = notification.id

          OpenStruct.new(action: :saved, notification_id: notification_id)
        end
      end

      private

      attr_reader :reaction, :receiver

      # when a notification exists in the db already it's safe to just save
      # when it doesn't, there could be a race condition when 2 jobs try to create duplicate notifications concurrently
      # in this case upsert is used to rely on postgres constraints and update or insert depending on if the record exists in the db at this point
      # currently, activerecord-import upsert is used
      # when the app is upgraded to Rails 6 this can be refactored to use rails upsert
      def save_notification(notification)
        if notification.persisted?
          notification.save!
          notification.id
        else
          # conflict target and index_predicate specify the index to use
          conflict_target = %i[notifiable_id notifiable_type]
          conflict_target << :action if notification.action?
          conflict_target << :user_id if notification.user_id?
          conflict_target << :organization_id if notification.organization_id?
          index_predicate = "action IS#{notification.action? ? ' NOT ' : ' '}NULL"
          import_result = Notification.import! [notification],
                                               on_duplicate_key_update: {
                                                 conflict_target: conflict_target,
                                                 index_predicate: index_predicate,
                                                 columns: %i[json_data notified_at read]
                                               }
          import_result.ids.first
        end
      end

      def reaction_json_data(recent_reaction, siblings)
        {
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
            aggregated_siblings: siblings,
            updated_at: recent_reaction.updated_at
          }
        }
      end
    end
  end
end
