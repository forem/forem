# frozen_string_literal: true

require 'capybara/dsl'
require 'capybara/rspec/matchers'
require 'capybara/rspec/matcher_proxies'

World(Capybara::DSL)
World(Capybara::RSpecMatchers)

After do
  Capybara.reset_sessions!
end

Before do
  Capybara.use_default_driver
end

Before '@javascript' do
  Capybara.current_driver = Capybara.javascript_driver
end

Before do |scenario|
  scenario.source_tag_names.each do |tag|
    driver_name = tag.sub(/^@/, '').to_sym
    Capybara.current_driver = driver_name if Capybara.drivers[driver_name]
  end
end
