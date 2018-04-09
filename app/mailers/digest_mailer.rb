class DigestMailer < ApplicationMailer
  def digest_email(user, articles)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @articles = articles.first(6)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)
    @digest_email = true
    mail(from: "DEV Digest <yo@dev.to>", to: @user.email, subject: "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}") do |format|
      format.html { render "layouts/mailer" }
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
    [
      "more posts picked just for you",
      "more trending DEV posts",
      "other posts you might like",
      "other posts you should read",
      "other articles picked for you",
      "more wonderful posts",
    ].sample
  end
end
