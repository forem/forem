Around "@ruby-2-7" do |scenario, block|
  if RUBY_VERSION.to_f == 2.7
    block.call
  else
    warn "Skipping scenario #{scenario.title} on Ruby v#{RUBY_VERSION}"
  end
end
