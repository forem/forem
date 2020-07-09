# Preview all emails at http://localhost:3000/rails/mailers/digest_mailer
class DigestMailerPreview < ActionMailer::Preview
  def digest_email
    DigestMailer.with(user: User.last, articles: Article.all).digest_email
  end
end
