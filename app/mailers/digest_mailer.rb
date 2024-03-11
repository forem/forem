class DigestMailer < ApplicationMailer
  include FieldTest::Helpers
  default from: -> { email_from(I18n.t("mailers.digest_mailer.from")) }

  def digest_email
    @user = params[:user]
    @articles = params[:articles]
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)

    subject = generate_title

    # set sendgrid category in the header using smtp api
    # https://docs.sendgrid.com/for-developers/sending-email/building-an-x-smtpapi-header
    if ForemInstance.sendgrid_enabled?
      smtpapi_header = { category: "Digest Email" }.to_json
      headers["X-SMTPAPI"] = smtpapi_header
    end

    mail(to: @user.email, subject: subject)
  end

  def title_test_variant(user)
    field_test(:digest_title_03_11, participant: user)
  end

  private

  def generate_title
    base = "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}"
    return base unless FeatureFlag.enabled?(:digest_subject_testing)

    title_variant = title_test_variant(@user)
    case title_variant
    when "base"
      base
    when "base_with_no_emoji"
      "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase}"
    when "base_with_start_with_dev_digest"
      "DEV Digest: #{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}"
    when "base_with_start_with_dev_digest_and_no_emoji"
      "DEV Digest: #{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase}"
    when "just_first_title"
      @articles.first.title
    when "just_first_title_and_dev_digest"
      "#{@articles.first.title} | DEV Digest"
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
