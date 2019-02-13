Rails.configuration.stripe = {
  publishable_key: ApplicationConfig["STRIPE_PUBLISHABLE_KEY"],
  secret_key: ApplicationConfig["STRIPE_SECRET_KEY"],
  stripe_cancellation_secret: ApplicationConfig["STRIPE_CANCELLATION_SECRET"]
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
