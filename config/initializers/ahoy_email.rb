# enable tracking for open, click and UTM params
AhoyEmail.api = false
AhoyEmail.default_options[:click] = Rails.env.production? ? ENV["AHOY_EMAIL_CLICK_ON"] == "YES" : true
AhoyEmail.default_options[:utm_params] = false
AhoyEmail.default_options[:message] = true
