# Preview all emails at http://localhost:3000/rails/mailers/digest_mailer
class CustomMailerPreview < ActionMailer::Preview
  def custom_email
    user = User.last
    content = "<h1 style='font-size:30px;color:red'>Custom Email Content</h1><p>This is a custom email content.</p>"
    subject = "Custom Email Subject"
    CustomMailer.with(user: user, content: content, subject: subject).custom_email
  end
end
