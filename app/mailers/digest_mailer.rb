class DigestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: -> { email_from(I18n.t("mailers.digest_mailer.from")) }

  def digest_email
    @user = params[:user]
    @articles = params[:articles]
    @billboards = params[:billboards]
    @smart_summary = params[:smart_summary]
    @feed_config_id = params[:feed_config_id]
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)
    @user_follows_any_subforems = user_follows_any_subforems?

    subject = generate_title

    customerio_delivery_options(
      transactional_message_id: "dev_digest_email",
      message_data: {
        "subject" => subject,
        "articles" => @articles.map { |article| digest_article_payload(article) },
        # Raw Markdown -- the SMTP view runs this through ContentRenderer before
        # display, so the CIO template needs to render it too.
        "smart_summary" => @smart_summary,
        "billboards_html" => digest_billboards_html,
        "email_end_phrase" => email_end_phrase,
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe),
        "user_follows_any_subforems" => @user_follows_any_subforems
      },
    )

    # set sendgrid category in the header using smtp api
    # https://docs.sendgrid.com/for-developers/sending-email/building-an-x-smtpapi-header
    if ForemInstance.sendgrid_enabled?
      smtpapi_header = { category: "Digest Email" }.to_json
      headers["X-SMTPAPI"] = smtpapi_header
    end

    mail(to: @user.email, subject: subject)
  end

  def user_follows_any_subforems?
    user_activity = @user.user_activity
    followed_subforem_ids = user_activity&.alltime_subforems || []
    default_subforem_id = Subforem.cached_default_id

    # Check if user follows any subforems OR has a custom onboarding subforem
    followed_subforem_ids.any? ||
      (@user.onboarding_subforem_id.present? && @user.onboarding_subforem_id != default_subforem_id)
  end

  private

  # Mirrors the article fields rendered by digest_email.html.erb (title,
  # article_url with the same context/fc params, and the same ai_summary /
  # truncated-description fallback), so the Customer.io template can
  # reproduce the article list without duplicating selection logic.
  def digest_article_payload(article)
    {
      "title" => article.title.strip,
      "url" => ApplicationController.helpers.article_url(article, context: "digest", fc: @feed_config_id.presence),
      "summary" => article.ai_summary.presence ||
        ApplicationController.helpers.truncate(article.description, length: 180)
    }
  end

  # The view only ever renders @billboards.first and @billboards.second
  # (as raw processed_html, not a partial) in two different markup contexts
  # (digest_email.html.erb:40-56 vs. :95-100); mirror that exactly rather
  # than rendering the whole array. Keyed by slot (not a plain array) so
  # that when only one of the two is selected -- a normal state, since the
  # worker resolves digest_first and digest_second independently -- the CIO
  # template can still tell which slot the surviving HTML belongs to.
  def digest_billboards_html
    {
      "first" => @billboards&.first&.processed_html,
      "second" => @billboards&.second&.processed_html
    }
  end

  def generate_title
    # Winner of digest_title_03_11
    if ForemInstance.dev_to?
      # Check if user follows any subforems
      if user_follows_any_subforems?
        "#{@articles.first.title} | Forem Digest"
      else
        "#{@articles.first.title} | DEV Digest"
      end
    else
      @articles.first.title
    end
  end

  def adjusted_title(article)
    title = article.title.strip
    "\"#{title}\"" unless title.start_with? '"'
  end

  def random_emoji
    ["🤓", "🎉", "🙈", "🔥", "💬", "👋", "👏", "🐶", "🦁", "🐙", "🦄", "❤️", "😇"].shuffle.take(3).join
  end

  def email_end_phrase
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)
    # "more trending posts" won the previous split test
    # Included more often as per explore-exploit algorithm
    [
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.other_posts"),
      I18n.t("mailers.digest_mailer.other_community_posts", community: community_name),
      I18n.t("mailers.digest_mailer.other_trending_posts", community: community_name),
      I18n.t("mailers.digest_mailer.other_top_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_top_posts", community: community_name),
      I18n.t("mailers.digest_mailer.more_top_posts_from"),
      I18n.t("mailers.digest_mailer.more_top_posts_based", community: community_name),
      I18n.t("mailers.digest_mailer.more_trending_posts_picked", community: community_name),
    ].sample
  end
end
