class DigestMailer < ApplicationMailer
  default from: -> { email_from(I18n.t("mailers.digest_mailer.from")) }

  def digest_email
    @user = params[:user]
    @articles = params[:articles]
    @billboards = params[:billboards]
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)
    @user_follows_any_subforems = user_follows_any_subforems?

    subject = generate_title

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
    community_name = Settings::Community.community_name
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
