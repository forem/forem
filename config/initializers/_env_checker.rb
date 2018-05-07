# This file is named in such a manner so that it run first.

keys = [
  "AIRBRAKE_API_KEY",
  "AIRBRAKE_PROJECT_ID",
  "ALGOLIASEARCH_API_KEY",
  "ALGOLIASEARCH_APPLICATION_ID",
  "ALGOLIASEARCH_SEARCH_ONLY_KEY",
  "APP_DOMAIN",
  "APP_PROTOCOL",
  "AWS_DEFAULT_REGION",
  "AWS_SDK_KEY",
  "AWS_SDK_SECRET",
  "AWS_S3_VIDEO_ID",
  "AWS_S3_VIDEO_KEY",
  "AWS_S3_INPUT_BUCKET",
  "BUFFER_ACCESS_TOKEN",
  "BUFFER_FACEBOOK_ID",
  "BUFFER_LINKEDIN_ID",
  "BUFFER_PROFILE_ID",
  "BUFFER_TWITTER_ID",
  "CLOUDINARY_API_KEY",
  "CLOUDINARY_API_SECRET",
  "CLOUDINARY_CLOUD_NAME",
  "CLOUDINARY_SECURE",
  "DACAST_STREAM_CODE",
  "DEPLOYMENT_SIGNATURE",
  "DEVTO_USER_ID",
  "GA_SERVICE_ACCOUNT_JSON",
  "GA_TRACKING_ID",
  "GA_VIEW_ID",
  "GITHUB_KEY",
  "GITHUB_SECRET",
  "GITHUB_TOKEN",
  "JWPLAYER_API_KEY",
  "JWPLAYER_API_SECRET",
  "KEEN_API_URL",
  "KEEN_PROJECT_ID",
  "KEEN_READ_KEY",
  "KEEN_WRITE_KEY",
  "MAILCHIMP_API_KEY",
  "MAILCHIMP_NEWSLETTER_ID",
  "PERIODIC_EMAIL_DIGEST_MAX",
  "PERIODIC_EMAIL_DIGEST_MIN",
  "PUSHER_APP_ID",
  "PUSHER_CLUSTER",
  "PUSHER_KEY",
  "PUSHER_SECRET",
  "RECAPTCHA_SECRET",
  "RECAPTCHA_SITE",
  "SENDBIRD_APP_ID",
  "SENDBIRD_LIVECHAT_URL",
  "SERVICE_TIMEOUT",
  "SHARE_MEOW_BASE_URL",
  "SHARE_MEOW_SECRET_KEY",
  "SLACK_CHANNEL",
  "SLACK_WEBHOOK_URL",
  "STREAM_RAILS_KEY",
  "STREAM_RAILS_SECRET",
  "STREAM_URL",
  "STRIPE_PUBLISHABLE_KEY",
  "STRIPE_SECRET_KEY",
  "TWITTER_ACCESS_TOKEN",
  "TWITTER_ACCESS_TOKEN_SECRET",
  "TWITTER_KEY",
  "TWITTER_SECRET",
].freeze

missing = []

keys.each do |k|
  missing << k if ENV[k].nil?
end

# Run the checker when
# 1. Not in production
# 2. Not in CI
# 3. There are missing keys
if Rails.env != "production" && !ENV["CI"] && !missing.empty? && Rails.env != "test"
  message = <<~HEREDOC
    \n
    =====================================================
    Hey there DEVeloper!
    You are missing the [#{missing.length}] environment variable(s).
    Please obtain these missing key(s) and try again.
    -----------------------------------------------------
    #{missing.join("\n")}
    =====================================================
    \n
  HEREDOC
  raise message
end
