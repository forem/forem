class DigestMailer < ApplicationMailer
  def digest_email(user, articles)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @articles = articles.first(6)
    @digest_email = true
    mail(from: "yo@dev.to", to: @user.email, subject: "#{@articles.first.title} #{random_emoji} and #{@articles.size - 1} other top posts from your network.") do |format|
      format.html { render "layouts/mailer" }
    end
  end

  def random_emoji
    ["📖","🎉","🙈","🔥","💬","👋","👏","🐶","🦁","🦊","🐙","🦄","❤️"].shuffle.take(3).join
  end
end
