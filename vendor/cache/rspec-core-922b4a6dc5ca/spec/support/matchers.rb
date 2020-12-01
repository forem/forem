RSpec::Matchers.define :map_specs do |specs|
  match do |autotest|
    @specs = specs
    @autotest = prepare(autotest)
    autotest.test_files_for(@file) == specs
  end

  chain :to do |file|
    @file = file
  end

  failure_message do
    "expected #{@autotest.class} to map #{@specs.inspect} to #{@file.inspect}\ngot #{@actual.inspect}"
  end

  def prepare(autotest)
    find_order = @specs.dup << @file
    autotest.instance_exec { @find_order = find_order }
    autotest
  end
end

RSpec::Matchers.define :fail_with do |exception_klass|
  match do |example|
    !example.execution_result.example_skipped? &&
    failure_reason(example, exception_klass).nil?
  end

  failure_message do |example|
    "expected example to fail with a #{exception_klass} exception, but #{failure_reason(example, exception_klass)}"
  end

  def failure_reason(example, exception_klass)
    result = example.execution_result
    case
      when example.metadata[:pending] then "was pending"
      when result.status != :failed then result.status
      when !result.exception.is_a?(exception_klass) then "failed with a #{result.exception.class}"
      else nil
    end
  end
end

RSpec::Matchers.define :pass do
  match do |example|
    !example.execution_result.example_skipped? &&
    failure_reason(example).nil?
  end

  failure_message do |example|
    "expected example to pass, but #{failure_reason(example)}"
  end

  def failure_reason(example)
    result = example.metadata[:execution_result]
    case
      when example.metadata[:pending] then "was pending"
      when result.status != :passed then result.status
      else nil
    end
  end
end

RSpec::Matchers.module_exec do
  alias_method :have_failed_with, :fail_with
  alias_method :have_passed, :pass
end

RSpec::Matchers.define :be_pending_with do |message|
  match do |example|
    example.pending? &&
    !example.execution_result.example_skipped? &&
    example.execution_result.pending_exception &&
    example.execution_result.status == :pending &&
    example.execution_result.pending_message == message
  end

  failure_message do |example|
    "expected: example pending with #{message.inspect}\n     got: #{example.execution_result.pending_message.inspect}".tap do |msg|
      msg << " (but had no pending exception)" unless example.execution_result.pending_exception
    end
  end
end

RSpec::Matchers.define :be_skipped_with do |message|
  match do |example|
    example.skipped? &&
    example.pending? &&
    example.execution_result.example_skipped? &&
    example.execution_result.pending_message == message
  end

  failure_message do |example|
    "expected: example skipped with #{message.inspect}\n     got: #{example.execution_result.pending_message.inspect}"
  end
end

RSpec::Matchers.define :contain_files do |*expected_files|
  contain_exactly_matcher = RSpec::Matchers::BuiltIn::ContainExactly.new(expected_files.map { |f| File.expand_path(f) })

  match do |actual_files|
    files = actual_files.map { |f| File.expand_path(f) }
    contain_exactly_matcher.matches?(files)
  end

  failure_message { contain_exactly_matcher.failure_message }
  failure_message_when_negated { contain_exactly_matcher.failure_message_when_negated }
end

RSpec::Matchers.define :first_include do |first_snippet|
  chain :then_include, :second_snippet

  match do |string|
    string.include?(first_snippet) &&
      string.include?(second_snippet) &&
      string.index(first_snippet) < string.index(second_snippet)
  end
end

RSpec::Matchers.alias_matcher :a_file_collection, :contain_files

RSpec::Matchers.define_negated_matcher :avoid_outputting, :output
RSpec::Matchers.define_negated_matcher :exclude, :include
RSpec::Matchers.define_negated_matcher :excluding, :include
RSpec::Matchers.define_negated_matcher :a_string_excluding, :a_string_including
RSpec::Matchers.define_negated_matcher :avoid_changing,   :change
RSpec::Matchers.define_negated_matcher :a_hash_excluding, :include
