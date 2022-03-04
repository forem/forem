# Preview all emails at http://localhost:3000/rails/mailers/devise/mailer
module Devise
  class MailerPreview < ActionMailer::Preview
    def confirmation_instructions
      Devise::Mailer.confirmation_instructions(User.last, "faketoken")
    end

    def email_changed
      Devise::Mailer.email_changed(User.last)
    end

    def password_change
      Devise::Mailer.password_change(User.last)
    end

    def reset_password_instructions
      Devise::Mailer.reset_password_instructions(User.last, "faketoken")
    end

    def unlock_instructions
      Devise::Mailer.unlock_instructions(User.last, "faketoken")
    end

    def creator_confirmation_instructions
      Devise::Mailer.confirmation_instructions(User.with_role(:creator).first, "faketoken")
    end
  end
end
