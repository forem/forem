# send notifications about the new reaction
module Notifications
  module Reactions
    class Send
      Response = Struct.new(:action, :notification_id)

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

      def self.call(...)
        new(...).call
      end

      # @return [OpenStruct, #action, #notification_id]
      def call
        return unless receiver.is_a?(User) || receiver.is_a?(Organization)

        reaction_siblings = Reaction.public_category.where(reactable_id: reaction.reactable_id,
                                                           reactable_type: reaction.reactable_type)
          .where.not(reactions: { user_id: reaction.reactable_user_id })
          .preload(:reactable).includes(:user).where.not(users: { id: nil })
          .order("reactions.created_at" => :desc)

        aggregated_reaction_siblings = reaction_siblings.map do |reaction|
          { category: reaction.category, created_at: reaction.created_at, user: user_data(reaction.user) }
        end

        notification_params = {
          notifiable_type: reaction.reactable_type,
          notifiable_id: reaction.reactable_id,
          action: "Reaction"
        }
        case receiver
        when User
          notification_params[:user_id] = receiver.id
        when Organization
          notification_params[:organization_id] = receiver.id
        end

        if aggregated_reaction_siblings.size.zero?
          Notification.where(notification_params).delete_all
          Response.new(:deleted)
        else
          recent_reaction = reaction_siblings.first

          json_data = reaction_json_data(recent_reaction, aggregated_reaction_siblings)

          previous_siblings_size = 0
          notification = Notification.find_or_initialize_by(notification_params)

          old_json_data = notification.json_data
          previous_siblings_size = notification.json_data["reaction"]["aggregated_siblings"].size if old_json_data

          notification.json_data = json_data
          notification.notified_at = Time.current
          notification.read = false if json_data[:reaction][:aggregated_siblings].size > previous_siblings_size

          notification_id = save_notification(notification_params, notification)

          Response.new(:saved, notification_id)
        end
      end

      private

      attr_reader :reaction, :receiver

      # when a notification exists in the DB already it's safe to just save it,
      # when it doesn't, there could be a race condition when 2 jobs try to create
      # duplicate notifications concurrently, in this case upsert is used to
      # rely on PostgreSQL constraints, thus we use `.upsert`
      def save_notification(params, notification)
        if notification.persisted?
          notification.save!
          notification.id
        else
          # in the upsert, we are only interested in updating the following columns:
          # json_data, notified_at, read and the notification params used by `.find_or_initialize_by`
          upsert_columns = %w[json_data notified_at read]
          upsert_attributes = notification.attributes.select { |k| upsert_columns.include?(k) }
          upsert_attributes.merge!(params)

          # unfortunately Rails requires the timestamps to be present even if unused in case of upsert
          # see <https://github.com/rails/rails/issues/35493>
          now = Time.current
          upsert_attributes["created_at"] = upsert_attributes["updated_at"] = now

          # we also need to select the correct index to let PostgreSQL know
          # how to determine conflict on rows
          upsert_index = choose_upsert_index(notification)

          upsert_result = Notification.upsert(
            upsert_attributes,
            unique_by: upsert_index,
            returning: %i[id],
          )

          upsert_result.to_a.first["id"]
        end
      end

      def choose_upsert_index(notification)
        # if none of these is present, we use the two columns for the upsert
        return %i[notifiable_id notifiable_type] unless
          notification.action? || notification.user_id? || notification.organization_id?

        if notification.action?
          return :index_notifications_on_user_notifiable_and_action_not_null if notification.user_id?

          :index_notifications_on_org_notifiable_and_action_not_null
        else
          return :index_notifications_on_user_notifiable_action_is_null if notification.user_id?

          :index_notifications_on_org_notifiable_action_is_null
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
