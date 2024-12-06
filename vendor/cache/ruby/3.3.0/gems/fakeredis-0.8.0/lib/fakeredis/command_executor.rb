module FakeRedis
  module CommandExecutor
    def write(command)
      meffod = command[0].to_s.downcase.to_sym
      args = command[1..-1]

      if in_multi && !(TRANSACTION_COMMANDS.include? meffod) # queue commands
        queued_commands << [meffod, *args]
        reply = 'QUEUED'
      elsif respond_to?(meffod) && method(meffod).arity.zero?
        reply = send(meffod)
      elsif respond_to?(meffod)
        reply = send(meffod, *args)
      else
        raise Redis::CommandError, "ERR unknown command '#{meffod}'"
      end

      replies << reply
      nil
    end
  end
end
