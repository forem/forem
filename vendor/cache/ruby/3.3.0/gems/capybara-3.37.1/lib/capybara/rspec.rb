# frozen_string_literal: true

require 'rspec/core'
require 'capybara/dsl'
require 'capybara/rspec/matchers'
require 'capybara/rspec/features'
require 'capybara/rspec/matcher_proxies'

RSpec.configure do |config|
  config.include Capybara::DSL, type: :feature
  config.include Capybara::RSpecMatchers, type: :feature
  config.include Capybara::DSL, type: :system
  config.include Capybara::RSpecMatchers, type: :system
  config.include Capybara::RSpecMatchers, type: :view

  # The before and after blocks must run instantaneously, because Capybara
  # might not actually be used in all examples where it's included.
  config.after do
    if self.class.include?(Capybara::DSL)
      Capybara.reset_sessions!
      Capybara.use_default_driver
    end
  end

  config.before do |example|
    if self.class.include?(Capybara::DSL)
      Capybara.current_driver = Capybara.javascript_driver if example.metadata[:js]
      Capybara.current_driver = example.metadata[:driver] if example.metadata[:driver]
    end
  end
end
