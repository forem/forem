Feature: `--warnings` option (run with warnings enabled)

  You can use the `--warnings` option to run specs with warnings enabled

  @unsupported-on-rbx
  Scenario:
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe do
        it 'generates warning' do
          $undefined
        end
      end
      """
    When I run `rspec --warnings example_spec.rb`
    Then the output should contain "warning"

  @ruby-2-7
  Scenario:
    Given a file named "example_spec.rb" with:
      """ruby
      def foo(**kwargs)
        kwargs
      end

      RSpec.describe do
       it "should warn about keyword arguments with 'rspec -w'" do
         expect(foo({a: 1})).to eq({a: 1})
        end
      end
      """
    When I run `rspec -w example_spec.rb`
    Then the output should contain "warning"

  @unsupported-on-rbx
  Scenario:
    Given a file named "example_spec.rb" with:
      """ruby
      RSpec.describe do
        it 'generates warning' do
          $undefined
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should not contain "warning"
