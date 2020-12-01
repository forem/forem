Feature: Use rspec-core without rspec-mocks or rspec-expectations

  It is most common to use rspec-core with rspec-mocks and rspec-expectations,
  and rspec-core will take care of loading those libraries automatically if
  available, but rspec-core can be used just fine without either of those
  gems installed.

  # Rubinius stacktrace includes kernel/loader.rb etc.
  @unsupported-on-rbx
  Scenario: Use only rspec-core when only it is installed
    Given only rspec-core is installed
      And a file named "core_only_spec.rb" with:
        """ruby
        RSpec.describe "Only rspec-core is available" do
          it "it fails when an rspec-mocks API is used" do
            dbl = double("MyDouble")
          end

          it "it fails when an rspec-expectations API is used" do
            expect(1).to eq(1)
          end
        end
        """
    When I run `rspec core_only_spec.rb`
    Then the output should contain "2 examples, 2 failures"
