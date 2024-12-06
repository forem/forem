module StripeMock
  def self.prepare_error(stripe_error, *handler_names)
    handler_names.push(:all) if handler_names.count == 0

    if @state == 'local'
      instance
    elsif @state == 'remote'
      client
    else
      raise UnstartedStateError
    end.error_queue.queue stripe_error, handler_names
  end

  def self.prepare_card_error(code, *handler_names)
    handler_names.push(:new_charge) if handler_names.count == 0

    error = CardErrors.build_error_for(code)
    if error.nil?
      raise StripeMockError, "Unrecognized stripe card error code: #{code}"
    end

    prepare_error error, *handler_names
  end

  module CardErrors
    def self.build_error_for(code)
      case code
      when :incorrect_number then build_card_error('The card number is incorrect', 'number', code: 'incorrect_number', http_status: 402)
      when :invalid_number then build_card_error('The card number is not a valid credit card number', 'number', code:  'invalid_number', http_status: 402)
      when :invalid_expiry_month then build_card_error("The card's expiration month is invalid", 'exp_month', code: 'invalid_expiry_month', http_status: 402)
      when :invalid_expiry_year then build_card_error("The card's expiration year is invalid", 'exp_year', code: 'invalid_expiry_year', http_status: 402)
      when :invalid_cvc then build_card_error("The card's security code is invalid", 'cvc', code: 'invalid_cvc', http_status: 402)
      when :expired_card then build_card_error('The card has expired', 'exp_month', code: 'expired_card', http_status: 402)
      when :incorrect_cvc then build_card_error("The card's security code is incorrect", 'cvc', code: 'incorrect_cvc', http_status: 402)
      when :card_declined then build_card_error('The card was declined', nil, code: 'card_declined', http_status: 402)
      when :missing then build_card_error('There is no card on a customer that is being charged.', nil, code: 'missing', http_status: 402)
      when :processing_error then build_card_error('An error occurred while processing the card', nil, code: 'processing_error', http_status: 402)
      when :card_error then build_card_error('The card number is not a valid credit card number.', 'number', code: 'invalid_number', http_status: 402)
      when :incorrect_zip then build_card_error('The zip code you supplied failed validation.', 'address_zip', code: 'incorrect_zip', http_status: 402)
      when :insufficient_funds then build_card_error('The card has insufficient funds to complete the purchase.', nil, code: 'insufficient_funds', http_status: 402)
      when :lost_card then build_card_error('The payment has been declined because the card is reported lost.', nil, code: 'lost_card', http_status: 402)
      when :stolen_card then build_card_error('The payment has been declined because the card is reported stolen.', nil, code: 'stolen_card', http_status: 402)
      end
    end

    def self.get_decline_code(code)
      decline_code_map = {
        card_declined: 'do_not_honor',
        missing: nil
      }
      decline_code_map.default = code.to_s

      code_key = code.to_sym
      decline_code_map[code_key]
    end

    def self.build_card_error(message, param, **kwargs)
      json_hash = {
        message: message,
        param: param,
        code: kwargs[:code],
        type: 'card_error',
        decline_code: get_decline_code(kwargs[:code])
      }

      error_keyword_args = kwargs.merge(json_body: { error: json_hash }, http_body: { error: json_hash }.to_json)

      Stripe::CardError.new(message, param, **error_keyword_args)
    end
  end
end
