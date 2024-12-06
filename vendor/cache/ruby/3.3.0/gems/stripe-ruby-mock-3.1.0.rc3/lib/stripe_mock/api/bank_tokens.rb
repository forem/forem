module StripeMock

  def self.generate_bank_token(bank_params = {})
    case @state
    when 'local'
      instance.generate_bank_token(bank_params)
    when 'remote'
      client.generate_bank_token(bank_params)
    else
      raise UnstartedStateError
    end
  end
end
