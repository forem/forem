module Constants
  module Settings
    module Authentication
      DETAILS = {
        allowed_registration_email_domains: {
          description: "Restrict registration to only certain emails? (comma-separated list)",
          placeholder: "dev.to, forem.com, codenewbie.org"
        },
        apple_client_id: {
          description:
          "The \"App Bundle\" code for the Authentication Service configured in the Apple Developer Portal",
          placeholder: "com.example.app"
        },
        apple_team_id: {
          description:
          "The \"Team ID\" of your Apple Developer Account",
          placeholder: ""
        },
        apple_key_id: {
          description:
          "The \"Key ID\" from the Authentication Service configured in the Apple Developer Portal",
          placeholder: ""
        },
        apple_pem: {
          description:
          "The \"PEM\" key from the Authentication Service configured in the Apple Developer Portal",
          placeholder: "-----BEGIN PRIVATE KEY-----\nMIGTAQrux...QPe8Yb\n-----END PRIVATE KEY-----\\n"
        },
        display_email_domain_allow_list_publicly: {
          description: "Do you want to display the list of allowed domains, or keep it private?"
        },
        facebook_key: {
          description:
          "The \"App ID\" portion of the Basic Settings section of the App page on the Facebook Developer Portal",
          placeholder: ""
        },
        facebook_secret: {
          description:
          "The \"App Secret\" portion of the Basic Settings section of the App page on the Facebook Developer Portal",
          placeholder: ""
        },
        github_key: {
          description: "The \"Client ID\" portion of the GitHub Oauth Apps portal",
          placeholder: ""
        },
        github_secret: {
          description: "The \"Client Secret\" portion of the GitHub Oauth Apps portal",
          placeholder: ""
        },
        invite_only_mode: {
          description: "Only users invited by email can join this community.",
          placeholder: ""
        },
        recaptcha_site_key: {
          description: "Add the site key for Google reCAPTCHA, which is used for reporting abuse",
          placeholder: "What is the Google reCAPTCHA site key?"
        },
        recaptcha_secret_key: {
          description: "Add the secret key for Google reCAPTCHA, which is used for reporting abuse",
          placeholder: "What is the Google reCAPTCHA secret key?"
        },
        require_captcha_for_email_password_registration: {
          description:
            "People will be required to fill out a captcha when they're creating a new account in your community",
          placeholder: ""
        },
        twitter_key: {
          description: "The \"API key\" portion of consumer keys in the Twitter developer portal.",
          placeholder: ""
        },
        twitter_secret: {
          description: "The \"API secret key\" portion of consumer keys in the Twitter developer portal.",
          placeholder: ""
        },
        providers: {
          description: "How can users sign in?",
          placeholder: ""
        }
      }.freeze
    end
  end
end
