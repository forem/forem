class DigestMailer < ApplicationMailer
  def digest_email(user, articles)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @articles = articles.first(6)
    @digest_email = true
    mail(from: "yo@dev.to", to: @user.email, subject: "#{@articles.first.title} #{random_emoji} and #{@articles.size - 1} #{email_end_phrase}") do |format|
      format.html { render "layouts/mailer" }
    end
  end

  def random_emoji
    ["📖","🎉","🙈","🔥","💬","👋","👏","🐶","🦁","🦊","🐙","🦄","❤️"].shuffle.take(3).join
  end

  def email_end_phrase
    [
      "more posts picked just for you",
      "more trending DEV posts",
      "other posts you might like",
      "other posts you should read",
      "other articles picked for you",
      "more wonderful posts"
    ].sample
  end
end
