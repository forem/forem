Around "@capybara" do |_scenario, block|
  require 'capybara'
  block.call
end
