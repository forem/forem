module StripeMock

  def self.toggle_live(toggle)
    if @state != 'ready' && @state != 'live'
      raise "You cannot toggle StripeMock live when it has already started."
    end
    if toggle
      @state = 'live'
      StripeMock.set_default_test_helper_strategy(:live)
    else
      @state = 'ready'
      StripeMock.set_default_test_helper_strategy(:mock)
    end
  end
end
