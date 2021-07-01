module Constants
  module Settings
    module SMTP
      DETAILS = {
        address: {
          description: "Address of the remote mail server",
          placeholder: "ie. smtp.gmail.com"
        },
        port: {
          description: "The port that your mail server runs on",
          placeholder: "25"
        },
        authentication: {
          description: " If your mail server requires authentication, " \
                       "you need to specify the authentication type here",
          placeholder: "ie. plain, login, or cram_md5"
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
        }
      }.freeze
    end
  end
end
