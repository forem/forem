require 'rspec/core/bisect/utilities'

FakeBisectRunner = Struct.new(:all_ids, :always_failures, :dependent_failures) do
  def start(_shell_command, _spec_runner)
    yield self
  end

  def original_results
    failures = always_failures | dependent_failures.keys
    RSpec::Core::Bisect::ExampleSetDescriptor.new(all_ids, failures.sort)
  end

  def run(ids)
    failures = ids & always_failures
    dependent_failures.each do |failing_example, depends_upon|
      failures << failing_example if dependency_satisfied?(depends_upon, ids)
    end

    RSpec::Core::Bisect::ExampleSetDescriptor.new(ids.sort, failures.sort)
  end

private

  def dependency_satisfied?(depends_upon, ids)
    depends_upon.all? { |d| ids.include?(d) }
  end
end
