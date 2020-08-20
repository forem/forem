if Rails.env.development? && Stripe.api_key.present?
  Stripe.log_level = Stripe::LEVEL_INFO
end
