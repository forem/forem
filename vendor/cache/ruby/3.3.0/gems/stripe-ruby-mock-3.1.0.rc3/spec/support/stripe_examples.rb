def require_stripe_examples
  Dir["./spec/shared_stripe_examples/**/*.rb"].each {|f| require f}
  Dir["./spec/integration_examples/**/*.rb"].each {|f| require f}
end

def it_behaves_like_stripe(&block)
  it_behaves_like 'Account API', &block
  it_behaves_like 'Account Link API', &block
  it_behaves_like 'Balance API', &block
  it_behaves_like 'Balance Transaction API', &block
  it_behaves_like 'Bank Account Token Mocking', &block
  it_behaves_like 'Card Token Mocking', &block
  it_behaves_like 'Card API', &block
  it_behaves_like 'Charge API', &block
  it_behaves_like 'Bank API', &block
  it_behaves_like 'Express Login Link API', &block
  it_behaves_like 'External Account API', &block
  it_behaves_like 'Coupon API', &block
  it_behaves_like 'Customer API', &block
  it_behaves_like 'Dispute API', &block
  it_behaves_like 'Extra Features', &block
  it_behaves_like 'Invoice API', &block
  it_behaves_like 'Invoice Item API', &block
  it_behaves_like 'Plan API', &block
  it_behaves_like 'Price API', &block
  it_behaves_like 'Product API', &block
  it_behaves_like 'Recipient API', &block
  it_behaves_like 'Refund API', &block
  it_behaves_like 'Transfer API', &block
  it_behaves_like 'Payout API', &block
  it_behaves_like 'PaymentIntent API', &block
  it_behaves_like 'PaymentMethod API', &block
  it_behaves_like 'SetupIntent API', &block
  it_behaves_like 'Stripe Error Mocking', &block
  it_behaves_like 'Customer Subscriptions with plans', &block
  it_behaves_like 'Customer Subscriptions with prices', &block
  it_behaves_like 'Subscription Items API', &block
  it_behaves_like 'Webhook Events API', &block
  it_behaves_like 'Country Spec API', &block
  it_behaves_like 'EphemeralKey API', &block
  it_behaves_like 'TaxRate API', &block
  it_behaves_like 'Checkout API', &block

  # Integration tests
  it_behaves_like 'Multiple Customer Cards'
  it_behaves_like 'Charging with Tokens'
  it_behaves_like 'Card Error Prep'
end
