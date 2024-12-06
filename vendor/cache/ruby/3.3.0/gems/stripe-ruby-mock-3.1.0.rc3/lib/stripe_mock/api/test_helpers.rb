module StripeMock

  def self.create_test_helper(strategy=nil)
    if strategy
      get_test_helper_strategy(strategy).new
    elsif @__test_strat
      @__test_strat.new
    else
      TestStrategies::Mock.new
    end
  end

  def self.set_default_test_helper_strategy(strategy)
    @__test_strat = get_test_helper_strategy(strategy)
  end

  def self.get_test_helper_strategy(strategy)
    case strategy.to_sym
    when :mock then TestStrategies::Mock
    when :live then TestStrategies::Live
    else raise "Invalid test helper strategy: #{strategy.inspect}"
    end
  end
end
