Rails.configuration.stripe = {
  publishable_key: ApplicationConfig["STRIPE_PUBLISHABLE_KEY"]
}

Stripe.api_key = ApplicationConfig["STRIPE_SECRET_KEY"]

if Rails.env.development? && Stripe.api_key.present?
  Stripe.log_level = Stripe::LEVEL_INFO
end
