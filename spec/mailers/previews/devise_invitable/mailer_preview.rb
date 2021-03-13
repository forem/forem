# Preview all emails at http://localhost:3000/rails/mailers/devise/mailer
module DeviseInvitable
  class MailerPreview < ActionMailer::Preview
    def invitation_instructions
      Devise::Mailer.invitation_instructions(User.last, "faketoken")
    end
  end
end
