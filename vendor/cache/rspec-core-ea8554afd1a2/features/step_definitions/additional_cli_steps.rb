require 'rspec/core'  # to fix annoying "undefined method `configuration' for RSpec:Module (NoMethodError)"

require './spec/support/formatter_support'

Then /^the output should contain all of these:$/ do |table|
  table.raw.flatten.each do |string|
    expect(all_output).to include(string)
  end
end

Then /^the output should not contain any of these:$/ do |table|
  table.raw.flatten.each do |string|
    expect(all_output).not_to include(string)
  end
end

Then /^the output should contain one of the following:$/ do |table|
  matching_output = table.raw.flatten.select do |string|
    all_output.include?(string)
  end

  expect(matching_output.count).to eq(1)
end

Then /^the example(?:s)? should(?: all)? pass$/ do
  step %q{the output should contain "0 failures"}
  step %q{the output should not contain "0 examples"}
  step %q{the exit status should be 0}
end

Then /^the example(?:s)? should(?: all)? fail$/ do
  step %q{the output should not contain "0 examples"}
  step %q{the output should not contain "0 failures"}
  step %q{the exit status should be 1}
  example_summary = /(\d+) examples?, (\d+) failures?/.match(all_output)
  example_count, failure_count = example_summary.captures
  expect(failure_count).to eq(example_count)
end

Then /^the process should succeed even though no examples were run$/ do
  step %q{the output should contain "0 examples, 0 failures"}
  step %q{the exit status should be 0}
end

addition_example_formatter_output = <<-EOS
Addition
  works
EOS

Then /^the output from `([^`]+)` (should(?: not)?) be in documentation format$/ do |cmd, should_or_not|
  step %Q{I run `#{cmd}`}
  step %q{the examples should all pass}
  step %Q{the output from "#{cmd}" #{should_or_not} contain "#{addition_example_formatter_output}"}
end

Then(/^the output from `([^`]+)` should indicate it ran only the subtraction file$/) do |cmd|
  step %Q{I run `#{cmd}`}
  step %q{the examples should all pass}
  step %Q{the output from "#{cmd}" should contain "1 example, 0 failures"}
  step %Q{the output from "#{cmd}" should contain "Subtraction"}
  step %Q{the output from "#{cmd}" should not contain "Addition"}
end

Then /^the backtrace\-normalized output should contain:$/ do |partial_output|
  # ruby 1.9 includes additional stuff in the backtrace,
  # so we need to normalize it to compare it with our expected output.
  normalized_output = all_output.split("\n").map do |line|
    line =~ /(^\s+# [^:]+:\d+)/ ? $1 : line # http://rubular.com/r/zDD7DdWyzF
  end.join("\n")

  expect(normalized_output).to include(partial_output)
end

Then /^the output should not contain any error backtraces$/ do
  step %q{the output should not contain "lib/rspec/core"}
end

# This step can be generalized if it's ever used to test other colors
Then /^the failing example is printed in magenta$/ do
  # \e[35m = enable magenta
  # \e[0m  = reset colors
  expect(all_output).to include("\e[35m" + "F" + "\e[0m")
end

Then /^the output from `([^`]+)` should contain "(.*?)"$/  do |cmd, expected_output|
  step %Q{I run `#{cmd}`}
  step %Q{the output from "#{cmd}" should contain "#{expected_output}"}
end

Then /^the output from `([^`]+)` should not contain "(.*?)"$/  do |cmd, expected_output|
  step %Q{I run `#{cmd}`}
  step %Q{the output from "#{cmd}" should not contain "#{expected_output}"}
end

Given /^I have a brand new project with no files$/ do
  cd('.') do
    expect(Dir["**/*"]).to eq([])
  end
end

Given /^I have run `([^`]*)`$/ do |cmd|
  run_command_and_stop(sanitize_text(cmd), :fail_on_error => true)
end

Given(/^a vendored gem named "(.*?)" containing a file named "(.*?)" with:$/) do |gem_name, file_name, file_contents|
  gem_dir = "vendor/#{gem_name}-1.2.3"
  step %Q{a file named "#{gem_dir}/#{file_name}" with:}, file_contents
  set_environment_variable('RUBYOPT', ENV['RUBYOPT'] + " -I#{gem_dir}/lib")
end

When "I accept the recommended settings by removing `=begin` and `=end` from `spec/spec_helper.rb`" do
  cd('.') do
    spec_helper = File.read("spec/spec_helper.rb")
    expect(spec_helper).to include("=begin", "=end")

    to_keep = spec_helper.lines.reject do |line|
      line.start_with?("=begin") || line.start_with?("=end")
    end

    File.open("spec/spec_helper.rb", "w") { |f| f.write(to_keep.join) }
    expect(File.read("spec/spec_helper.rb")).not_to include("=begin", "=end")
  end
end

When /^I create "([^"]*)" with the following content:$/ do |file_name, content|
  write_file(file_name, content)
end

Given(/^I have run `([^`]*)` once, resulting in "([^"]*)"$/) do |command, output_snippet|
  step %Q{I run `#{command}`}
  step %Q{the output from "#{command}" should contain "#{output_snippet}"}
end

When(/^I fix "(.*?)" by replacing "(.*?)" with "(.*?)"$/) do |file_name, original, replacement|
  cd('.') do
    contents = File.read(file_name)
    expect(contents).to include(original)
    fixed = contents.sub(original, replacement)
    File.open(file_name, "w") { |f| f.write(fixed) }
  end
end

Given(/^I have not configured `example_status_persistence_file_path`$/) do
  cd('.') do
    return unless File.exist?("spec/spec_helper.rb")
    return unless File.read("spec/spec_helper.rb").include?("example_status_persistence_file_path")
    File.open("spec/spec_helper.rb", "w") { |f| f.write("") }
  end
end

Given(/^files "(.*?)" through "(.*?)" with an unrelated passing spec in each file$/) do |file1, file2|
  index_1 = Integer(file1[/\d+/])
  index_2 = Integer(file2[/\d+/])
  pattern = file1.sub(/\d+/, '%s')

  index_1.upto(index_2) do |index|
    write_file(pattern % index, <<-EOS)
      RSpec.describe "Spec file #{index}" do
        example { }
      end
    EOS
  end
end

Then(/^bisect should (succeed|fail) with output like:$/) do |succeed, expected_output|
  last_process = all_commands.last
  expected_status = succeed == "succeed" ? 0 : 1
  expect(last_process.exit_status).to eq(expected_status),
    "Expected exit status of #{expected_status} but got #{last_process.exit_status} \n\n" \
    "Output:\n\n#{last_process.stdout}"

  expected = normalize_durations(expected_output)
  actual   = normalize_durations(last_process.stdout).sub(/\n+\Z/, '')

  if !RSpec::Support::RubyFeatures.fork_supported?
    expected.gsub!('runner: :fork', 'runner: :shell')
  end

  if expected.include?("# ...")
    expected_start, expected_end = expected.split("# ...")
    expect(actual).to start_with(expected_start).and end_with(expected_end)
  else
    expect(actual).to eq(expected)
  end
end

When(/^I run `([^`]+)` and abort in the middle with ctrl\-c$/) do |cmd|
  set_environment_variable('RUBYOPT', ENV['RUBYOPT'] + " -r#{File.expand_path("../../support/send_sigint_during_bisect.rb", __FILE__)}")
  step "I run `#{cmd}`"
end

Then(/^it should fail and list all the failures:$/) do |string|
  step %q{the exit status should not be 0}
  expect(normalize_failure_output(all_output)).to include(normalize_failure_output(string))
end

Then(/^it should pass and list all the pending examples:$/) do |string|
  step %q{the exit status should be 0}
  expect(normalize_failure_output(all_output)).to include(normalize_failure_output(string))
end

Then(/^the output should report "slow before context hook" as the slowest example group$/) do
  # These expectations are trying to guard against a regression that introduced
  # this output:
  #   Top 1 slowest example groups:
  #     slow before context hook
  #       Inf seconds average (0.00221 seconds / 0 examples) RSpec::ExampleGroups::SlowBeforeContextHook::Nested
  #
  # Problems:
  # - "Inf seconds"
  # - 0 examples
  # - "Nested" group listed (it should be the outer group)
  # - The example group class name is listed (it should be the location)

  output = all_output

  expect(output).not_to match(/nested/i)
  expect(output).not_to match(/inf/i)
  expect(output).not_to match(/\b0 examples/i)

  seconds = '\d+(?:\.\d+)? seconds'

  expect(output).to match(
    %r{Top 1 slowest example groups?:\n\s+slow before context hook\n\s+#{seconds} average \(#{seconds} / 1 example\) \./spec/example_spec\.rb:1}
  )
end

Given(/^I have changed `([^`]+)` to `([^`]+)` in "(.*?)"$/) do |old_code, new_code, file_name|
  cd('.') do
    file_content = File.read(file_name)
    expect(file_content).to include(old_code)
    new_file_content = file_content.sub(old_code, new_code)
    File.open(file_name, "w") { |f| f.write(new_file_content) }
  end
end

module Normalization
  def normalize_failure_output(text)
    whitespace_normalized = text.lines.map { |line| line.sub(/\s+$/, '').sub(/:in .*$/, '') }.join

    # 1.8.7 and JRuby produce slightly different output for `Hash#fetch` errors, so we
    # convert it to the same output here to match our expectation.
    whitespace_normalized.
      sub("IndexError", "KeyError").
      sub(/key not found.*$/, "key not found")
  end
end

World(Normalization)
World(FormatterSupport)
