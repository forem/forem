Feature: Spies

  [Message expectations](./expecting-messages) put an example's expectation at the start, before you've invoked the
  code-under-test. Many developers prefer using an arrange-act-assert (or given-when-then)
  pattern for structuring tests. Spies are an alternate type of test double that support this
  pattern by allowing you to expect that a message has been received after the fact, using
  `have_received`.

  You can use any test double (or partial double) as a spy, but the double must be setup to
  spy on the messages you care about. Spies automatically spy on all messages,
  or you can [allow a message](./allowing-messages) to spy on it.

  `have_received` supports the same fluent interface for [setting constraints](../setting-constraints) that normal message expectations do.

  Note: The `have_received` API shown here will only work if you are using rspec-expectations.
  Note: `have_received(...).with(...)` is unable to work properly when passed arguments are mutated after the spy records the received message.

  Scenario: Using a spy
    Given a file named "spy_spec.rb" with:
      """ruby
      RSpec.describe "have_received" do
        it "passes when the message has been received" do
          invitation = spy('invitation')
          invitation.deliver
          expect(invitation).to have_received(:deliver)
        end
      end
      """
    When I run `rspec spy_spec.rb`
    Then the examples should all pass

  Scenario: Spy on a method on a partial double
    Given a file named "partial_double_spy_spec.rb" with:
      """ruby
      class Invitation
        def self.deliver; end
      end

      RSpec.describe "have_received" do
        it "passes when the expectation is met" do
          allow(Invitation).to receive(:deliver)
          Invitation.deliver
          expect(Invitation).to have_received(:deliver)
        end
      end
      """
    When I run `rspec partial_double_spy_spec.rb`
    Then the examples should all pass

  Scenario: Failure when the message has not been received
    Given a file named "failure_spec.rb" with:
      """ruby
      class Invitation
        def self.deliver; end
      end

      RSpec.describe "failure when the message has not been received" do
        example "for a spy" do
          invitation = spy('invitation')
          expect(invitation).to have_received(:deliver)
        end

        example "for a partial double" do
          allow(Invitation).to receive(:deliver)
          expect(Invitation).to have_received(:deliver)
        end
      end
      """
     When I run `rspec failure_spec.rb --order defined`
     Then it should fail with:
      """
        1) failure when the message has not been received for a spy
           Failure/Error: expect(invitation).to have_received(:deliver)

             (Double "invitation").deliver(*(any args))
                 expected: 1 time with any arguments
                 received: 0 times with any arguments
      """
      And it should fail with:
      """
        2) failure when the message has not been received for a partial double
           Failure/Error: expect(Invitation).to have_received(:deliver)

             (Invitation (class)).deliver(*(any args))
                 expected: 1 time with any arguments
                 received: 0 times with any arguments
      """

  Scenario: Set constraints using the fluent interface
    Given a file named "setting_constraints_spec.rb" with:
      """ruby
      RSpec.describe "An invitiation" do
        let(:invitation) { spy("invitation") }

        before do
          invitation.deliver("foo@example.com")
          invitation.deliver("bar@example.com")
        end

        it "passes when a count constraint is satisfied" do
          expect(invitation).to have_received(:deliver).twice
        end

        it "passes when an order constraint is satisifed" do
          expect(invitation).to have_received(:deliver).with("foo@example.com").ordered
          expect(invitation).to have_received(:deliver).with("bar@example.com").ordered
        end

        it "fails when a count constraint is not satisfied" do
          expect(invitation).to have_received(:deliver).at_least(3).times
        end

        it "fails when an order constraint is not satisifed" do
          expect(invitation).to have_received(:deliver).with("bar@example.com").ordered
          expect(invitation).to have_received(:deliver).with("foo@example.com").ordered
        end
      end
      """
    When I run `rspec setting_constraints_spec.rb --order defined`
    Then it should fail with the following output:
      | 4 examples, 2 failures                                                                              |
      |                                                                                                     |
      |  1) An invitiation fails when a count constraint is not satisfied                                   |
      |     Failure/Error: expect(invitation).to have_received(:deliver).at_least(3).times                  |
      |       (Double "invitation").deliver(*(any args))                                                    |
      |           expected: at least 3 times with any arguments                                             |
      |           received: 2 times with any arguments                                                      |
      |                                                                                                     |
      |  2) An invitiation fails when an order constraint is not satisifed                                  |
      |     Failure/Error: expect(invitation).to have_received(:deliver).with("foo@example.com").ordered    |
      |       #<Double "invitation"> received :deliver out of order                                         |
