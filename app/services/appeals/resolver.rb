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

    # Written by Spam::Handler.audit_automatic_block! for every role the automation applies.
    AUTOMATIC_BLOCK_CATEGORY = "spam.automatic_block".freeze
    # Moderator::ManageActivityAndRoles records the role name as the note reason when a human
    # bans ("Suspended"/"Spam") or reinstates ("Good standing"/"Trusted") a user.
    MANUAL_BAN_NOTE_REASONS = %w[Suspended Spam].freeze
    MANUAL_CLEAR_NOTE_REASONS = ["Good standing", "Trusted"].freeze

    # Whether the appeal may be approved without a human. Only restrictions the automation applied
    # are eligible: if a moderator banned the user during the current restriction (before or after
    # the automation did), the appeal is left for human review.
    #
    # @return [Boolean]
    def self.auto_approvable?(appeal)
      user = appeal.user
      return true unless user.spam? || user.suspended?

      since = restriction_started_after(appeal)
      return false unless within(AuditLog.where(category: AUTOMATIC_BLOCK_CATEGORY).on_user(user), since).exists?

      !within(Note.where(noteable: user, reason: MANUAL_BAN_NOTE_REASONS), since).exists?
    end

    # The last time the user's restrictions were lifted (an approved appeal or a human reinstating
    # them). Anything older belongs to a previous, already resolved restriction.
    def self.restriction_started_after(appeal)
      user = appeal.user
      [
        FlagAppeal.approved.where(user_id: user.id).where.not(id: appeal.id).maximum(:updated_at),
        Note.where(noteable: user, reason: MANUAL_CLEAR_NOTE_REASONS).maximum(:created_at),
      ].compact.max
    end

    def self.within(relation, since)
      since ? relation.where("#{relation.table_name}.created_at > ?", since) : relation
    end

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
      @republished_article_ids = []
      @restriction_lifted = false
    end

    # Automated approvals (no admin) are refused when a human moderator applied the ban.
    def approve
      return false if @admin.nil? && !self.class.auto_approvable?(@appeal)

      resolved = resolve!(:approved) do
        republish_articles
        remove_restriction_roles
        reset_flagged_article_labels
        destroy_mascot_vomit_reactions
        create_approval_note
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
      @restriction_lifted = @user.spam_or_suspended?
      @user.remove_role(:suspended) if @user.suspended?
      @user.remove_role(:spam) if @user.spam?
    end

    # Every other path that adds or lifts these roles leaves a note, so moderators looking at the
    # user can see why they are no longer restricted.
    def create_approval_note
      Note.create(
        author_id: @admin&.id || Settings::General.mascot_user_id,
        noteable: @user,
        reason: "flag_appeal_approved",
        content: I18n.t("services.appeals.resolver.approved_note",
                        id: @appeal.id,
                        resolver: @admin&.username || I18n.t("services.appeals.resolver.automatic")),
      )
    end

    # Republishes the appealed article, or for an account appeal, the posts the automatic
    # suspension hid (as recorded by Spam::Handler.suspend!). Drafts (no published_at) stay drafts.
    #
    # update_all skips callbacks on purpose: Article's publish callbacks re-run the spam checks
    # (Articles::HandleSpamWorker), which could re-flag the author right after reinstatement.
    def republish_articles
      ids = case @target
            when Article then [@target.id]
            when User then automatically_unpublished_article_ids
            else []
            end
      return if ids.empty?

      articles = @user.articles.where(id: ids, published: false).where.not(published_at: nil)
      @republished_article_ids = articles.ids
      Article.where(id: @republished_article_ids).update_all(published: true)
    end

    # Union across the current restriction's suspension logs, since suspend! can run more than once.
    def automatically_unpublished_article_ids
      since = self.class.restriction_started_after(@appeal)
      logs = AuditLog.where(category: AUTOMATIC_BLOCK_CATEGORY, slug: "automatic_suspended").on_user(@user)
      self.class.within(logs, since).flat_map { |log| Array(log.data["unpublished_article_ids"]) }.uniq
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
      enqueue_score_recalculation

      # Label resets use update_all (no callbacks), so purge the edge cache for the profile and posts.
      Users::BustCacheWorker.perform_async(@user.id)
      busted_article_ids = @reset_article_ids | @republished_article_ids
      Articles::BustMultipleCachesWorker.perform_async(busted_article_ids) if busted_article_ids.any?
    end

    # Spam and suspended roles lower the scores of all the author's articles and comments, directly or
    # through the author's own score (Article#calculate_score, Comments::CalculateScore). Lifting one
    # means recalculating all of them, as Moderator::ManageActivityAndRoles does. Otherwise only the
    # appealed content needs it.
    def enqueue_score_recalculation
      if @restriction_lifted
        @user.articles.published.find_each(&:async_score_calc)
        @user.comments.find_each(&:calculate_score)
        return
      end

      case @target
      when Comment then Comments::CalculateScoreWorker.perform_async(@target.id)
      when Article then Articles::ScoreCalcWorker.perform_async(@target.id)
      end
    end
  end
end
