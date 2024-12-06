module StripeMock

  def self.toggle_debug(toggle)
    if @state == 'local'
      @instance.debug = toggle
    elsif @state == 'remote'
      @client.set_server_debug(toggle)
    end
  end

end
