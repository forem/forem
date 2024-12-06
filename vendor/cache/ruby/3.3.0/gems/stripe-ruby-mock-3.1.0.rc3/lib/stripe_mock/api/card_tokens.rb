module StripeMock

  def self.generate_card_token(card_params = {})
    case @state
    when 'local'
      instance.generate_card_token(card_params)
    when 'remote'
      client.generate_card_token(card_params)
    else
      raise UnstartedStateError
    end
  end
end
