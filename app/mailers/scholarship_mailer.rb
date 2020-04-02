class ScholarshipMailer < ApplicationMailer
  def scholarship_awarded_email(user)
    @user = user
    mail(from: "members@dev.to", to: @user.email, subject: "Congrats on your DEV Scholarship!")
  end
end
