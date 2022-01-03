module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      DATA = Struct.new(:total, :verified, keyword_init: true)

      def initialize(user:)
        @user = user
        @emails = emails
        @notes = notes
        @credits = credits
        @organizations = organizations
        @reports = reports
        @reactions = reactions
      end

      private

      attr_reader :user

      def emails
        DATA.new(
          total: [user.email_messages.count, 50].min, # we only display 50 emails at most
          verified: EmailAuthorization.last_verification_date(user).present?,
        )
      end

      def notes
        DATA.new(
          total: [user.notes.count, 10].min, # we only display 10 notes at most
        )
      end

      def credits
        DATA.new(
          total: user.unspent_credits_count,
        )
      end

      def organizations
        DATA.new(
          total: user.organizations.count,
        )
      end

      def reports
        DATA.new(
          # we only display 15 reports at most
          total: [FeedbackMessage.all_user_reports(user).count, 15].min,
        )
      end

      def reactions
        DATA.new(
          # we only display 15 reactions at most
          total: [Reaction.related_negative_reactions_for_user(user).count, 15].min,
        )
      end
    end
  end
end
