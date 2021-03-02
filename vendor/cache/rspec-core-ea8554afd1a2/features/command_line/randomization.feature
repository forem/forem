Feature: Randomization can be reproduced across test runs

  In Ruby, randomness is seeded by calling `srand` and passing it the seed that
  you want to use. By doing this, subsequent calls to `rand`, `shuffle`,
  `sample`, etc. will all be randomized the same way given the same seed is
  passed to `srand`.

  RSpec takes care not to seed randomization directly when taking action that
  involves randomness (such as random ordering of examples).

  Since RSpec does not ever invoke `srand`, this means that you are free to
  choose which, if any, mechanism is used to seed randomization.

  There is an example below of how to use RSpec's seed for this purpose if you
  wish to do so.

  If you would like to manage seeding randomization without any help from RSpec,
  please keep the following things in mind:

    * The seed should never be hard-coded.

      The first example below only does this to show that seeding randomization
      with a seed other than the one used by RSpec will correctly seed
      randomization.

    * Report the seed that was chosen.

      The randomization that was used for a given test run can not be reproduced
      if no one knows what seed was used to begin with.

    * Provide a mechanism to feed the seed into the tests.

      Without this, the call to `srand` will have to be hard-coded any time it
      is necessary to replicate a given test run's randomness.

  Background:
    Given a file named ".rspec" with:
      """
      --require spec_helper
      """

    Given a file named "spec/random_spec.rb" with:
      """ruby
      RSpec.describe 'randomized example' do
        it 'prints random numbers' do
          puts 5.times.map { rand(99) }.join("-")
        end
      end
      """

  Scenario: Specifying a seed using `srand` provides predictable randomization
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      srand 123
      """
    When I run `rspec`
    Then the output should contain "66-92-98-17-83"

  Scenario: Passing the RSpec seed to `srand` provides predictable randomization
    Given a file named "spec/spec_helper.rb" with:
      """ruby
      srand RSpec.configuration.seed
      """
    When I run `rspec --seed 123`
    Then the output should contain "66-92-98-17-83"
