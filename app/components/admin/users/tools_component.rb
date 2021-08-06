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
          verified: user.last_verification_date.present?,
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
          total: [user.reports.count, 15].min, # we only display 15 reports at most
        )
      end

      def reactions
        DATA.new(
          total: [user.related_negative_reactions.count, 15].min, # we only display 15 reactions at most
        )
      end
    end
  end
end
