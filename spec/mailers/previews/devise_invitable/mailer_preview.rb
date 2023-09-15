# Preview all emails at http://localhost:3000/rails/mailers/devise/mailer
module DeviseInvitable
  class MailerPreview < ActionMailer::Preview
    def invitation_instructions
      user = User.invite!(email: "test@email.com",
                          username: "username")
      options = {
        custom_invite_subject: "Custom subject!!",
        custom_invite_message: "# Hey!\n\nJoin [our Forem](https://example.com).\n\n## Testing!",
        custom_invite_footnote: "Custom footnote! _Yay_"
      }
      Devise.mailer.invitation_instructions(user, "faketoken", options)
    end
  end
end
