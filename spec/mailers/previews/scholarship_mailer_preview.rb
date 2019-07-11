# Preview all emails at http://localhost:3000/rails/mailers/scholarship_mailer
class ScholarshipMailerPreview < ActionMailer::Preview
  def scholarship_awarded_email
    ScholarshipMailer.scholarship_awarded_email(User.last)
  end
end
