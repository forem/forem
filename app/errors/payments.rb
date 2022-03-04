module Payments
  class PaymentsError < StandardError
  end

  class InvalidRequestError < PaymentsError
  end

  class CardError < PaymentsError
  end
end
