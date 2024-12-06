module StripeMock

  def self.set_account_balance(value)
    case @state
      when 'local'
      instance.account_balance = value
    when 'remote'
      client.set_account_balance(value)
    else
      raise UnstartedStateError
    end
  end

end
