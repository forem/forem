module Appeals
  ##
  # Resolves a FlagAppeal by approving (unflagging/reinstating) or rejecting it.
  class Resolver
    def self.approve(appeal:, admin: nil)
      new(appeal: appeal, admin: admin).approve
    end

    def self.reject(appeal:, admin: nil)
      new(appeal: appeal, admin: admin).reject
    end

    def initialize(appeal:, admin: nil)
      @appeal = appeal
      @user = appeal.user
      @target = appeal.appealable
      @admin = admin
    end

    def approve
      ActiveRecord::Base.transaction do
        # 1. Update user roles if user was suspended or marked as spam
        if @user.spam_or_suspended?
          @user.remove_role(:suspended) if @user.suspended?
          @user.remove_role(:spam) if @user.spam?
        end

        # 2. Reset automod label on Article target
        if @target.is_a?(Article)
          @target.update_columns(automod_label: "no_moderation_label")
        end

        # 3. Clean up mascot vomit reactions on the target content / user
        destroy_spam_reactions

        # 4. Mark appeal approved
        @appeal.update!(
          status: :approved,
          resolved_by: @admin,
        )
      end

      # 5. Recalculate scores outside the transaction to prevent deadlocks with concurrent Sidekiq workers
      if @target.is_a?(Comment)
        Comments::CalculateScoreWorker.perform_async(@target.id)
      elsif @target.is_a?(Article)
        Articles::ScoreCalcWorker.perform_async(@target.id)
      end

      true
    end

    def reject
      @appeal.update!(
        status: :rejected,
        resolved_by: @admin,
      )
      true
    end

    private

    def destroy_spam_reactions
      mascot_id = Settings::General.mascot_user_id
      return unless mascot_id

      Reaction.where(
        user_id: mascot_id,
        reactable: @target,
        category: "vomit",
      ).destroy_all
    end
  end
end
