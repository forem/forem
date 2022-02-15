module Constants
  module Settings
    module SMTP
      DETAILS = {
        address: {
          description: "Address of the remote mail server",
          placeholder: "i.e. smtp.gmail.com"
        },
        port: {
          description: "The port that your mail server runs on",
          placeholder: "25"
        },
        authentication: {
          description: " If your mail server requires authentication, " \
                       "you need to specify the authentication type here. " \
                       " i.e. plain, login, or cram_md5",
          placeholder: "i.e. plain, login, or cram_md5"
        },
        user_name: {
          description: "If your mail server requires authentication, copy the username from your server",
          placeholder: ""
        },
        password: {
          description: "If your mail server requires authentication, copy the password from your server",
          placeholder: ""
        },
        domain: {
          description: "If you need to specify a HELO domain, you can do it here",
          placeholder: ""
        },
        from_email_address: {
          description: "The email address that emails should be sent from",
          placeholder: ""
        },
        reply_to_email_address: {
          description: "The email address that users can reply to",
          placeholder: ""
        }
      }.freeze
    end
  end
end
