module StripeMock

  def self.global_id_prefix
    if StripeMock.client
      StripeMock.client.server_global_id_prefix
    else
      case @global_id_prefix
        when false then ""
        when nil then "test_"
        else @global_id_prefix
      end
    end
  end

  def self.global_id_prefix=(value)
    if StripeMock.client
      StripeMock.client.set_server_global_id_prefix(value)
    else
      @global_id_prefix = value
    end
  end
end
