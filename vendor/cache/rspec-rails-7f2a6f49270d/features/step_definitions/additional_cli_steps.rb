begin
  require "active_job"
rescue LoadError # rubocop:disable Lint/SuppressedException
end
begin
  require "action_cable"
rescue LoadError # rubocop:disable Lint/SuppressedException
end
begin
  require "active_storage"
  require "action_mailbox"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

require "rails/version"

require "rspec/rails/feature_check"

Then /^the example(s)? should( all)? pass$/ do |_, _|
  step 'the output should contain "0 failures"'
  step 'the exit status should be 0'
end

Then /^the example(s)? should( all)? fail/ do |_, _|
  step 'the output should not contain "0 failures"'
  step 'the exit status should not be 0'
end

Given /active job is available/ do
  unless RSpec::Rails::FeatureCheck.has_active_job?
    pending "ActiveJob is not available"
  end
end

Given /action cable testing is available/ do
  unless RSpec::Rails::FeatureCheck.has_action_cable_testing?
    pending "Action Cable testing is not available"
  end
end

Given /action mailbox is available/ do
  unless RSpec::Rails::FeatureCheck.has_action_mailbox?
    pending "Action Mailbox is not available"
  end
end
