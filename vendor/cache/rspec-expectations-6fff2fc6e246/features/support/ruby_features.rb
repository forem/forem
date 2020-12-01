Around "@skip-when-splat-args-unsupported" do |scenario, block|
  require 'rspec/support/ruby_features'

  if ::RSpec::Support::RubyFeatures.optional_and_splat_args_supported?
    block.call
  else
    warn "Skipping scenario #{scenario.title} because splat arguments are not supported"
  end
end

Around "@skip-when-keyword-args-unsupported" do |scenario, block|
  require 'rspec/support/ruby_features'

  if ::RSpec::Support::RubyFeatures.kw_args_supported?
    block.call
  else
    warn "Skipping scenario #{scenario.title} because keyword arguments are not supported"
  end
end

Around "@skip-when-required-keyword-args-unsupported" do |scenario, block|
  require 'rspec/support/ruby_features'

  if ::RSpec::Support::RubyFeatures.required_kw_args_supported?
    block.call
  else
    warn "Skipping scenario #{scenario.title} because required keyword arguments are not supported"
  end
end

Around "@skip-when-ripper-unsupported" do |scenario, block|
  require 'rspec/support/ruby_features'

  if ::RSpec::Support::RubyFeatures.ripper_supported?
    block.call
  else
    warn "Skipping scenario #{scenario.title} because Ripper is not supported"
  end
end
