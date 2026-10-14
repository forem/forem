# Reconciles an article's co-author invitations with the invitee list chosen in the editor.
#
# - Users new to the list get a pending invitation (which notifies them).
# - Users dropped from the list have their invitation withdrawn, and lose their co-author credit
#   if they had already accepted.
# - Declined invitations are kept, so the author can't keep re-inviting someone who said no.
#
# The list is validated before the article is saved, so a bad list never leaves a half-saved
# post behind: call #prepare once the article's new attributes are assigned, save the article only
# if it returns true, then call #apply.
module CoAuthorInvitations
  class Sync
    attr_reader :errors

    # @param article [Article] may be unsaved, but must have its author assigned
    # @param invitee_ids [Array<Integer, String>] everyone who should be invited or credited
    def initialize(article, invitee_ids)
      @article = article
      @invitee_ids = Array.wrap(invitee_ids).compact_blank.map(&:to_i).uniq
      @errors = []
    end

    # Validates the list before the article is saved.
    #
    # @return [Boolean] whether the list is valid
    def prepare
      validate_list
      new_invitations.each { |invitation| errors.concat(invitation.errors.full_messages) if invitation.invalid? }
      errors.empty?
    end

    # Persists the reconciled invitations. The article must have been saved.
    def apply
      # Lock the article row the way Accept and Decline do, so a response that landed after
      # #prepare is seen here. A separate instance is locked because reloading the caller's article
      # would discard the saved_changes its caller still checks.
      Article.transaction do
        locked_article = Article.lock.find(article.id)
        withdraw(locked_article)
        next if locked_article.organization_id.present?

        # Eligibility was checked in #prepare; if it changed in the moment since (an unfollow,
        # a concurrent save of the same post), no invitation is sent rather than failing the save.
        new_invitations.each(&:save)
      end
    end

    private

    attr_reader :article, :invitee_ids

    def validate_list
      if article.organization_id.present? && invitee_ids.any? && new_invitations.empty?
        errors << I18n.t("models.co_author_invitation.personal_posts_only")
      end

      if invitee_ids.size > CoAuthorInvitation::MAX_PER_ARTICLE
        errors << I18n.t("models.co_author_invitation.too_many", count: CoAuthorInvitation::MAX_PER_ARTICLE)
      end

      existing_invitations.select { |invitation| invitation.declined? && invitee_ids.include?(invitation.user_id) }
        .each do |invitation|
          errors << I18n.t("models.co_author_invitation.declined", username: invitation.user.username)
        end
    end

    # Re-reads the withdrawn invitations under the lock: anyone who accepted (before or after
    # #prepare) loses their credit, and anyone who declined keeps their invitation as declined.
    def withdraw(locked_article)
      invitations = CoAuthorInvitation.where(id: withdrawn_invitations.map(&:id)).reject(&:declined?)
      credited_ids = invitations.filter_map { |invitation| invitation.user_id if invitation.accepted? }
      credited_ids &= locked_article.co_author_ids

      invitations.each(&:destroy!)
      return if credited_ids.empty?

      locked_article.update!(co_author_ids: locked_article.co_author_ids - credited_ids)
      article.co_author_ids = locked_article.co_author_ids
    end

    def existing_invitations
      @existing_invitations ||= article.new_record? ? [] : article.co_author_invitations.includes(:user).to_a
    end

    def withdrawn_invitations
      @withdrawn_invitations ||= existing_invitations.reject do |invitation|
        invitation.declined? || invitee_ids.include?(invitation.user_id)
      end
    end

    def new_invitations
      @new_invitations ||= (invitee_ids - existing_invitations.map(&:user_id)).map do |user_id|
        CoAuthorInvitation.new(article: article, user_id: user_id)
      end
    end
  end
end
