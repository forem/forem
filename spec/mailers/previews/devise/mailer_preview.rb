# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
module Devise
  # :nodoc:
  class MailerPreview < ActionMailer::Preview
    def confirmation_instructions
      Devise::Mailer.confirmation_instructions(User.last, "faketoken")
    end

    def email_changed
      Devise::Mailer.email_changed(User.last, User.last.email)
    end

    def invitation_instructions
      Devise::Mailer.email_changed(User.last, "faketoken")
    end

    def password_changed
      Devise::Mailer.email_changed(User.last)
    end

    def reset_password_instructions
      Devise::Mailer.email_changed(User.last, "faketoken")
    end

    def unlock_instructions
      Devise::Mailer.reset_password_instructions(User.last, "faketoken")
    end
  end
end
