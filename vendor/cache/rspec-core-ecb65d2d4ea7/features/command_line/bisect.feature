@with-clean-spec-opts
Feature: Bisect

  RSpec's `--order random` and `--seed` options help surface flickering examples that only fail when one or more other examples are executed first. It can be very difficult to isolate the exact combination of examples that triggers the failure. The `--bisect` flag helps solve that problem.

  Pass the `--bisect` option (in addition to `--seed` and any other options) and RSpec will repeatedly run subsets of your suite in order to isolate the minimal set of examples that reproduce the same failures.

  At any point during the bisect run, you can hit ctrl-c to abort and it will provide you with the most minimal reproduction command it has discovered so far.

  To get more detailed output (particularly useful if you want to report a bug with bisect), use `--bisect=verbose`.

  Background:
    Given a file named "lib/calculator.rb" with:
      """ruby
      class Calculator
        def self.add(x, y)
          x + y
        end
      end
      """
    And a file named "spec/calculator_1_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "Calculator" do
        it 'adds numbers' do
          expect(Calculator.add(1, 2)).to eq(3)
        end
      end
      """
    And files "spec/calculator_2_spec.rb" through "spec/calculator_9_spec.rb" with an unrelated passing spec in each file
    And a file named "spec/calculator_10_spec.rb" with:
      """ruby
      require 'calculator'

      RSpec.describe "Monkey patched Calculator" do
        it 'does screwy math' do
          # monkey patching `Calculator` affects examples that are
          # executed after this one!
          def Calculator.add(x, y)
            x - y
          end

          expect(Calculator.add(5, 10)).to eq(-5)
        end
      end
      """

  Scenario: Use `--bisect` flag to create a minimal repro case for the ordering dependency
    When I run `rspec --seed 1234`
    Then the output should contain "10 examples, 1 failure"
    When I run `rspec --seed 1234 --bisect`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 1234"
      Running suite to find failures... (0.16755 seconds)
      Starting bisect with 1 failing example and 9 non-failing examples.
      Checking that failure(s) are order-dependent... failure appears to be order-dependent

      Round 1: bisecting over non-failing examples 1-9 .. ignoring examples 6-9 (0.30166 seconds)
      Round 2: bisecting over non-failing examples 1-5 .. ignoring examples 4-5 (0.30306 seconds)
      Round 3: bisecting over non-failing examples 1-3 .. ignoring example 3 (0.33292 seconds)
      Round 4: bisecting over non-failing examples 1-2 . ignoring example 1 (0.16476 seconds)
      Bisect complete! Reduced necessary non-failing examples from 9 to 1 in 1.26 seconds.

      The minimal reproduction command is:
        rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234
      """
    When I run `rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234`
    Then the output should contain "2 examples, 1 failure"

  Scenario: Ctrl-C can be used to abort the bisect early and get the most minimal command it has discovered so far
    When I run `rspec --seed 1234 --bisect` and abort in the middle with ctrl-c
    Then bisect should fail with output like:
      """
      Bisect started using options: "--seed 1234"
      Running suite to find failures... (0.17102 seconds)
      Starting bisect with 1 failing example and 9 non-failing examples.
      Checking that failure(s) are order-dependent... failure appears to be order-dependent

      Round 1: bisecting over non-failing examples 1-9 .. ignoring examples 6-9 (0.32943 seconds)
      Round 2: bisecting over non-failing examples 1-5 .. ignoring examples 4-5 (0.3154 seconds)
      Round 3: bisecting over non-failing examples 1-3 .. ignoring example 3 (0.2175 seconds)

      Bisect aborted!

      The most minimal reproduction command discovered so far is:
        rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] --seed 1234
      """
    When I run `rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] --seed 1234`
    Then the output should contain "3 examples, 1 failure"

  Scenario: Use `--bisect=verbose` to enable verbose debug mode for more detail
    When I run `rspec --seed 1234 --bisect=verbose`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 1234" and bisect runner: :fork
      Running suite to find failures... (0.16528 seconds)
       - Failing examples (1):
          - ./spec/calculator_1_spec.rb[1:1]
       - Non-failing examples (9):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_5_spec.rb[1:1]
          - ./spec/calculator_6_spec.rb[1:1]
          - ./spec/calculator_7_spec.rb[1:1]
          - ./spec/calculator_8_spec.rb[1:1]
          - ./spec/calculator_9_spec.rb[1:1]
      Checking that failure(s) are order-dependent..
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] --seed 1234 (n.nnnn seconds)
       - Failure appears to be order-dependent
      Round 1: bisecting over non-failing examples 1-9
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_6_spec.rb[1:1] ./spec/calculator_7_spec.rb[1:1] ./spec/calculator_8_spec.rb[1:1] ./spec/calculator_9_spec.rb[1:1] --seed 1234 (0.15302 seconds)
       - Running: rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_2_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] ./spec/calculator_4_spec.rb[1:1] ./spec/calculator_5_spec.rb[1:1] --seed 1234 (0.19708 seconds)
       - Examples we can safely ignore (4):
          - ./spec/calculator_6_spec.rb[1:1]
          - ./spec/calculator_7_spec.rb[1:1]
          - ./spec/calculator_8_spec.rb[1:1]
          - ./spec/calculator_9_spec.rb[1:1]
       - Remaining non-failing examples (5):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_5_spec.rb[1:1]
      Round 2: bisecting over non-failing examples 1-5
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_4_spec.rb[1:1] ./spec/calculator_5_spec.rb[1:1] --seed 1234 (0.15836 seconds)
       - Running: rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_2_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] --seed 1234 (0.19065 seconds)
       - Examples we can safely ignore (2):
          - ./spec/calculator_4_spec.rb[1:1]
          - ./spec/calculator_5_spec.rb[1:1]
       - Remaining non-failing examples (3):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_2_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
      Round 3: bisecting over non-failing examples 1-3
       - Running: rspec ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_2_spec.rb[1:1] --seed 1234 (0.21028 seconds)
       - Running: rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] ./spec/calculator_3_spec.rb[1:1] --seed 1234 (0.1975 seconds)
       - Examples we can safely ignore (1):
          - ./spec/calculator_2_spec.rb[1:1]
       - Remaining non-failing examples (2):
          - ./spec/calculator_10_spec.rb[1:1]
          - ./spec/calculator_3_spec.rb[1:1]
      Round 4: bisecting over non-failing examples 1-2
       - Running: rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234 (0.17173 seconds)
       - Examples we can safely ignore (1):
          - ./spec/calculator_3_spec.rb[1:1]
       - Remaining non-failing examples (1):
          - ./spec/calculator_10_spec.rb[1:1]
      Bisect complete! Reduced necessary non-failing examples from 9 to 1 in 1.47 seconds.

      The minimal reproduction command is:
        rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234
      """
    When I run `rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234`
    Then the output should contain "2 examples, 1 failure"

  Scenario: Pick a bisect runner via a config option
    Given a file named "spec/spec_helper.rb" with:
      """
      RSpec.configure do |c|
        c.bisect_runner = :shell
      end
      """
    And a file named ".rspec" with:
      """
      --require spec_helper
      """
    When I run `rspec --seed 1234 --bisect=verbose`
    Then bisect should succeed with output like:
      """
      Bisect started using options: "--seed 1234" and bisect runner: :shell
      # ...
      The minimal reproduction command is:
        rspec ./spec/calculator_10_spec.rb[1:1] ./spec/calculator_1_spec.rb[1:1] --seed 1234
      """
