class DigestMailer < ApplicationMailer
  def digest_email(user, articles)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @articles = articles.first(6)
    @digest_email = true
    mail(from: "yo@dev.to", to: @user.email, subject: "Emai!") do |format|
      format.html { render "layouts/mailer" }
    end
  end
end
