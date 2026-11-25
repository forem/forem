module Feeds
  class ResolveAuthor
    def self.call(item, feed_source)
      new(item, feed_source).call
    end

    def initialize(item, feed_source)
      @item = item
      @feed_source = feed_source
    end

    def call
      find_by_email || find_by_name || fallback_author
    end

    private

    attr_reader :item, :feed_source

    def author_string
      @author_string ||= item.try(:author)&.strip
    end

    def extracted_email_and_name
      return @extracted_email_and_name if defined?(@extracted_email_and_name)

      @extracted_email_and_name =
        ForemNative.extract_feed_author(author_string) || [
          author_string[/[\w.+-]+@[\w.-]+\.\w+/],
          author_string.sub(/<[^>]+>/, "").strip,
        ]
    end

    # Scope author lookup to active organization members when the feed owner is an
    # admin of the selected organization; otherwise only the feed owner themselves.
    def eligible_users
      @eligible_users ||= if can_assign_org_authors?
                            feed_source.organization.active_users
                          else
                            User.where(id: feed_source.user_id)
                          end
    end

    def can_assign_org_authors?
      return @can_assign_org_authors if defined?(@can_assign_org_authors)

      @can_assign_org_authors =
        feed_source.organization_id.present? && feed_source.user.org_admin?(feed_source.organization_id)
    end

    def fallback_author
      return feed_source.user if feed_source.author_user_id.blank? || feed_source.author_user_id == feed_source.user_id

      active_org_author? ? feed_source.effective_author : feed_source.user
    end

    def active_org_author?
      can_assign_org_authors? && OrganizationMembership.active.exists?(
        user_id: feed_source.author_user_id,
        organization_id: feed_source.organization_id,
      )
    end

    def preloaded_owner
      return if can_assign_org_authors?
      return unless feed_source.association(:user).loaded?

      feed_source.user
    end

    def find_by_email
      return if author_string.blank?

      # Extract email from formats like "Name <email@example.com>" or plain "email@example.com"
      email, = extracted_email_and_name
      return unless email

      if (owner = preloaded_owner)
        return owner if owner.email == email

        return
      end

      eligible_users.find_by(email: email)
    end

    def find_by_name
      return if author_string.blank?

      # Strip email if present (e.g., "John Doe <john@example.com>" → "John Doe")
      _, name = extracted_email_and_name
      return if name.blank?

      if (owner = preloaded_owner)
        return owner if owner.name == name

        return
      end

      eligible_users.find_by(name: name)
    end
  end
end
