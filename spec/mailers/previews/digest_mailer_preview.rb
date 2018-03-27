# Preview all emails at http://localhost:3000/rails/mailers/notify_mailer
class DigestMailerPreview < ActionMailer::Preview
  def digest_email
    DigestMailer.digest_email(User.last, Article.all)
  end
end
