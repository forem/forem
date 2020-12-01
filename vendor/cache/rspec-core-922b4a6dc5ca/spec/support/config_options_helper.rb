module ConfigOptionsHelper
  extend RSpec::SharedContext

  around(:each) { |e| without_env_vars('SPEC_OPTS', &e) }

  def config_options_object(*args)
    RSpec::Core::ConfigurationOptions.new(args)
  end

  def parse_options(*args)
    config_options_object(*args).options
  end
end
