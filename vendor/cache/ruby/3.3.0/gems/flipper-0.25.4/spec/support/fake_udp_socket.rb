class FakeUDPSocket
  attr_reader :buffer

  def initialize
    @buffer = []
  end

  def send(message, *_rest)
    @buffer.push [message]
  end

  def recv
    @buffer.shift
  end

  def clear
    @buffer = []
  end

  def to_s
    inspect
  end

  def inspect
    "<FakeUDPSocket: #{@buffer.inspect}>"
  end
end
