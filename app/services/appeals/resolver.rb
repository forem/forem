module Appeals
  ##
  # Resolves a FlagAppeal by approving (unflagging/reinstating) or rejecting it.
  #
  # Resolution is idempotent: the appeal row is locked and re-checked, so a double-submit, an admin
  # racing the AI worker, or a replayed request returns +false+ instead of re-running side effects.
  class Resolver
    # Labels the automated spam pipeline puts on flagged articles. They are reset on approval so a
    # reinstated author isn't immediately re-counted by the repeat-offender checks.
    FLAGGED_AUTOMOD_LABELS = (Spam::Handler::CLEAR_VIOLATION_LABELS +
                              %w[likely_spam likely_harmful likely_inciting]).freeze
    RESET_AUTOMOD_LABEL = "no_moderation_label".freeze

    # @return [Boolean] false when the appeal was already resolved
    def self.approve(appeal:, admin: nil)
      new(appeal: appeal, admin: admin).approve
    end

    # @return [Boolean] false when the appeal was already resolved
    def self.reject(appeal:, admin: nil)
      new(appeal: appeal, admin: admin).reject
    end

    def initialize(appeal:, admin: nil)
      @appeal = appeal
      @user = appeal.user
      @target = appeal.appealable
      @admin = admin
      @reset_article_ids = []
    end

    def approve
      resolved = resolve!(:approved) do
        remove_restriction_roles
        reset_flagged_article_labels
        destroy_mascot_vomit_reactions
      end
      return false unless resolved

      # Follow-up work runs outside the transaction to avoid deadlocks with concurrent Sidekiq workers.
      enqueue_follow_up_jobs
      true
    end

    def reject
      resolve!(:rejected)
    end

    private

    # Locks the appeal, bails out if somebody already resolved it, and otherwise runs the optional
    # block and records the resolution in a single transaction.
    def resolve!(status)
      @appeal.with_lock do
        next false if @appeal.approved? || @appeal.rejected?

        yield if block_given?
        @appeal.update!(status: status, resolved_by: @admin)
        true
      end
    end

    def remove_restriction_roles
      @user.remove_role(:suspended) if @user.suspended?
      @user.remove_role(:spam) if @user.spam?
    end

    def reset_flagged_article_labels
      articles = @user.articles.where(automod_label: FLAGGED_AUTOMOD_LABELS)
      articles = articles.or(@user.articles.where(id: @target.id)) if @target.is_a?(Article)

      @reset_article_ids = articles.ids
      Article.where(id: @reset_article_ids).update_all(automod_label: RESET_AUTOMOD_LABEL)
    end

    # Only the mascot's automated vomit reactions are removed; reactions from moderators and
    # community members are left alone.
    def destroy_mascot_vomit_reactions
      mascot_id = Settings::General.mascot_user_id
      return unless mascot_id

      vomits = Reaction.where(user_id: mascot_id, category: "vomit")
      vomits.where(reactable_type: "Article", reactable_id: @user.articles.select(:id)).destroy_all
      vomits.where(reactable_type: "User", reactable_id: @user.id).destroy_all
      vomits.where(reactable: @target).destroy_all if @target.is_a?(Comment)
    end

    def enqueue_follow_up_jobs
      case @target
      when Comment then Comments::CalculateScoreWorker.perform_async(@target.id)
      when Article then Articles::ScoreCalcWorker.perform_async(@target.id)
      end

      # Label resets use update_all (no callbacks), so purge the edge cache for the profile and posts.
      Users::BustCacheWorker.perform_async(@user.id)
      Articles::BustMultipleCachesWorker.perform_async(@reset_article_ids) if @reset_article_ids.any?
    end
  end
end
