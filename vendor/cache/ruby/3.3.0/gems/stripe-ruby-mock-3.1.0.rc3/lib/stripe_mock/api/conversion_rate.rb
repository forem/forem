module StripeMock

  def self.set_conversion_rate(value)
    case @state
    when 'local'
      instance.conversion_rate = value
    when 'remote'
      client.set_conversion_rate(value)
    else
      raise UnstartedStateError
    end
  end

end
