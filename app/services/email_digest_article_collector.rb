class EmailDigestArticleCollector
  include FieldTest::Helpers
  include Instrumentation

  ARTICLES_TO_SEND = "EmailDigestArticleCollector#articles_to_send".freeze
  RESULTS_COUNT = 7 # Winner of digest_count_03_18 field test
  CLICK_LOOKBACK = 30

  def initialize(user)
    @user = user
  end

  def articles_to_send
    # rubocop:disable Metrics/BlockLength
    order = Arel.sql("((score * ((feed_success_score * 12) + 0.1)) - (clickbait_score * 2)) DESC")
    instrument ARTICLES_TO_SEND, tags: { user_id: @user.id } do
      return [] unless should_receive_email?

      articles = if @user.cached_followed_tag_names.any?
                   # Set subforem context for followed subforems or default
                   set_subforem_context

                   articles_query = @user.followed_articles
                     .select(:title, :description, :path, :cached_user, :cached_tag_list, :subforem_id)
                     .published
                     .full_posts
                     .where("published_at > ?", cutoff_date)
                     .where(email_digest_eligible: true)
                     .not_authored_by(@user.id)
                     .where("score > ?", 8)

                   # Only filter by subforem if we're not skipping subforem filtering
                   articles_query = articles_query.where(subforem_id: @subforem_ids) unless @skip_subforem_filtering

                   articles_query.order(order).limit(RESULTS_COUNT)
                 else
                   tags = @user.cached_followed_tag_names_or_recent_tags
                   # Set subforem context for followed subforems or default
                   set_subforem_context

                   if @skip_subforem_filtering
                     # If skipping subforem filtering, get articles from anywhere
                     articles_query = Article.select(
                       :title, :description, :path, :cached_user, :cached_tag_list, :subforem_id
                     )
                       .published
                       .full_posts
                       .where("published_at > ?", cutoff_date)
                       .where(email_digest_eligible: true)
                       .not_authored_by(@user.id)
                       .where("score > ?", 11)
                       .merge(Article.featured.or(Article.cached_tagged_with_any(tags)))
                       .order(order)
                       .limit(RESULTS_COUNT)
                   else
                     # Normal logic with subforem filtering and tags
                     articles_query = Article.select(
                       :title, :description, :path, :cached_user, :cached_tag_list, :subforem_id
                     )
                       .published
                       .full_posts
                       .where("published_at > ?", cutoff_date)
                       .where(email_digest_eligible: true)
                       .not_authored_by(@user.id)
                       .where("score > ?", 11)
                       .where(subforem_id: @subforem_ids)
                       .order(order)
                       .limit(RESULTS_COUNT)
                       .merge(Article.featured.or(Article.cached_tagged_with_any(tags)))
                   end
                 end

      # Fallback if there are not enough articles
      if articles.length < 3
        if @skip_subforem_filtering
          # If we're skipping subforem filtering, get articles from anywhere
          articles_query = Article.select(:title, :description, :path, :cached_user, :cached_tag_list, :subforem_id)
            .published
            .full_posts
            .where("published_at > ?", cutoff_date)
            .where(email_digest_eligible: true)
            .where("score > ?", 11)
        else
          # For fallback, include both followed subforems and default subforem
          fallback_subforem_ids = @subforem_ids.dup
          default_subforem_id = Subforem.cached_default_id
          if default_subforem_id && fallback_subforem_ids.exclude?(default_subforem_id)
            fallback_subforem_ids << default_subforem_id
          end

          articles_query = Article.select(:title, :description, :path, :cached_user, :cached_tag_list, :subforem_id)
            .published
            .full_posts
            .where("published_at > ?", cutoff_date)
            .where(email_digest_eligible: true)
            .where("score > ?", 11)
            .where(subforem_id: fallback_subforem_ids)
        end

        articles = articles_query.not_authored_by(@user.id)
          .order(order)
          .limit(RESULTS_COUNT)

        if @user.cached_antifollowed_tag_names.any?
          articles = articles.not_cached_tagged_with_any(@user.cached_antifollowed_tag_names)
        end
      end

      # Pop second article to front if the first article is the same as the last email
      if articles.any? && last_email_includes_title_in_subject?(articles.first.title)
        articles = articles[1..] + [articles.first]
      end

      articles.length < 3 ? [] : articles
    end
    # rubocop:enable Metrics/BlockLength
  end

  def should_receive_email?
    return true unless last_email_sent
    return false if last_email_sent > 18.hours.ago
    return true if last_email_clicked?

    email_sent_within_lookback_period = last_email_sent >= Settings::General.periodic_email_digest.days.ago
    return false if email_sent_within_lookback_period && !recent_tracked_click?

    true
  end

  private

  def set_subforem_context
    # Get user's followed subforems from UserActivity
    user_activity = @user.user_activity
    followed_subforem_ids = user_activity&.alltime_subforems || []
    default_subforem_id = Subforem.cached_default_id

    # Check if user has a custom onboarding subforem (not nil and not default)
    has_custom_onboarding = @user.onboarding_subforem_id.present? &&
      @user.onboarding_subforem_id != default_subforem_id

    if followed_subforem_ids.any?
      # User follows subforems - use those
      @subforem_ids = followed_subforem_ids
      @skip_subforem_filtering = false
    elsif has_custom_onboarding
      # User has custom onboarding subforem - don't filter by subforem at all
      @subforem_ids = []
      @skip_subforem_filtering = true
    else
      # User doesn't follow any subforems and has no custom onboarding - use default subforem
      @subforem_ids = default_subforem_id ? [default_subforem_id] : []
      @skip_subforem_filtering = false
    end
  end

  def recent_tracked_click?
    @user.email_messages
      .where(mailer: "DigestMailer#digest_email")
      .where("sent_at > ?", CLICK_LOOKBACK.days.ago)
      .where.not(clicked_at: nil).any?
  end

  def last_email_clicked?
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.clicked_at.present?
  end

  def last_email_sent
    @last_email_sent ||=
      @user.email_messages
        .where(mailer: "DigestMailer#digest_email")
        .maximum(:sent_at)
  end

  def last_email_includes_title_in_subject?(title)
    @user.email_messages
      .where(mailer: "DigestMailer#digest_email")
      .last&.subject&.include?(title)
  end

  def cutoff_date
    a_few_days_ago = 7.days.ago.utc
    return a_few_days_ago unless last_email_sent

    [a_few_days_ago, (last_email_sent - 18.hours)].max
  end

  def user_has_followings?
    @user.following_users_count.positive? ||
      @user.cached_followed_tag_names.any? ||
      @user.cached_antifollowed_tag_names.any?
  end
end
