class DigestMailer < ApplicationMailer
  default from: -> { email_from("Digest") }

  def digest_email
    @user = params[:user]
    @articles = params[:articles]
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)

    subject = generate_title
    mail(to: @user.email, subject: subject)
  end

  private

  def generate_title
    "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}"
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
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "more trending #{community_name} posts",
      "other posts you might like",
      "other #{community_name} posts you might like",
      "other trending #{community_name} posts",
      "other top #{community_name} posts",
      "more top #{community_name} posts",
      "more top reads from the community",
      "more top #{community_name} posts based on your interests",
      "more trending #{community_name} posts picked for you",
    ].sample
  end
end
