module Notifications
  def self.user_data(user)
    {
      id: user.id,
      class: { name: "User" },
      name: user.name,
      username: user.username,
      path: user.path,
      profile_image_90: user.profile_image_90,
      comments_count: user.comments_count,
      created_at: user.created_at
    }
  end

  def self.comment_data(comment)
    {
      id: comment.id,
      class: { name: "Comment" },
      path: comment.path,
      processed_html: comment.processed_html,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      ancestry: comment.ancestry,
      depth: comment.depth,
      ancestors: ancestor_data(comment),
      commentable: {
        id: comment.commentable.id,
        title: comment.commentable.title,
        path: comment.commentable.path,
        class: {
          name: comment.commentable.class.name
        }
      }
    }
  end

  def self.article_data(article)
    {
      id: article.id,
      cached_tag_list_array: article.decorate.cached_tag_list_array,
      class: { name: "Article" },
      title: article.title,
      path: article.path,
      updated_at: article.updated_at,
      published_at: article.published_at,
      readable_publish_date: article.readable_publish_date,
      reading_time: article.reading_time
    }
  end

  def self.organization_data(organization)
    {
      id: organization.id,
      class: { name: "Organization" },
      name: organization.name,
      slug: organization.slug,
      path: organization.path,
      profile_image_90: organization.profile_image_90
    }
  end

  def self.native_article_payload(article)
    user = article.user
    return unless user

    user_created_sec, user_created_ms = utc_sec_millis(user.created_at)
    return if user_created_sec == :defer

    article_updated_sec, article_updated_ms = utc_sec_millis(article.updated_at)
    return if article_updated_sec == :defer

    article_published_sec, article_published_ms = utc_sec_millis(article.published_at)
    return if article_published_sec == :defer

    user_fields = [
      user.id,
      user.name,
      user.username,
      user.path,
      user.profile_image_90,
      user.comments_count,
      user_created_sec,
      user_created_ms,
    ]

    article_fields = [
      article.id,
      article.cached_tag_list,
      article.title,
      article.path,
      article_updated_sec,
      article_updated_ms,
      article_published_sec,
      article_published_ms,
      article.readable_publish_date,
      article.reading_time,
    ]

    org_fields = if article.organization_id
                   org = article.organization
                   return unless org

                   [org.id, org.name, org.slug, org.path, org.profile_image_90]
                 end

    [user_fields, article_fields, org_fields]
  end

  def self.article_bulk_upsert_sql(user_ids:, article:, action:, now:, returning_id: false)
    return if user_ids.empty? || !native_bulk_upsert_supported?(now)

    payload = native_article_payload(article)
    return unless payload

    user_fields, article_fields, org_fields = payload
    ForemNative.build_article_notification_bulk_upsert_sql(
      user_ids,
      article.class.name,
      article.subforem_id,
      action,
      user_fields,
      article_fields,
      org_fields,
      now.tv_sec,
      now.usec,
      returning_id: returning_id,
    )
  end

  def self.native_bulk_upsert_supported?(now)
    ForemNative.available? &&
      ActiveRecord.default_timezone == :utc &&
      ActiveSupport::JSON::Encoding.use_standard_json_time_format &&
      ActiveSupport::JSON::Encoding.time_precision == 3 &&
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json &&
      now.respond_to?(:tv_sec) && now.respond_to?(:usec)
  end
  private_class_method :native_bulk_upsert_supported?

  def self.utc_sec_millis(time)
    return [nil, nil] if time.nil?
    return [:defer, nil] unless time.respond_to?(:utc?) && time.utc? &&
      time.respond_to?(:tv_sec) && time.respond_to?(:nsec)

    [time.tv_sec, time.nsec / 1_000_000]
  end
  private_class_method :utc_sec_millis

  def self.ancestor_data(comment)
    comment.ancestors.includes(:user).map do |ancestor|
      {
        id: ancestor.id,
        title: ancestor.title,
        path: ancestor.path,
        ancestry: ancestor.ancestry,
        depth: ancestor.depth,
        user: {
          username: ancestor.user.username,
          name: ancestor.user.name
        }
      }
    end
  end
  private_class_method :ancestor_data
end
