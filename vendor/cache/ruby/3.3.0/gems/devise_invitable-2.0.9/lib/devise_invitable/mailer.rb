require 'devise/version'

module DeviseInvitable
  module Mailer

    # Deliver an invitation email
    def invitation_instructions(record, token, opts = {})
      @token = token
      devise_mail(record, :invitation_instructions, opts)
    end
  end
end
