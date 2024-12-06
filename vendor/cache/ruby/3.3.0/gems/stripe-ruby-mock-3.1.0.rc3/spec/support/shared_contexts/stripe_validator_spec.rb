
class StripeValidator
  include StripeMock::RequestHandlers::ParamValidators
end

RSpec.shared_context "stripe validator", shared_context: :metadata do
  let(:stripe_validator) { StripeValidator.new }
end