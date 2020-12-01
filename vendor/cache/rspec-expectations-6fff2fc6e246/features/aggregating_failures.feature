Feature: Aggregating Failures

  Normally, an expectation failure causes the example to immediately abort.  When you have multiple independent expectations, it's nice to be able to see all of the failures rather than just the first.  One solution is to split off a separate example for each expectation, but if the setup for the examples is slow, that's going to take extra time and slow things down.  `aggregate_failures` provides an alternate solution.  It wraps a set of expectations with a block.  Within the block, expectation failures will not immediatly abort like normal; instead, the failures will be aggregated into a single exception that is raised at the end of the block, allowing you to see all expectations that failed.

  `aggregate_failures` takes an optional string argument that will be used in the aggregated failure message as a label.

  RSpec::Core expands this feature a bit; see [the rspec-core docs](https://relishapp.com/rspec/rspec-core/docs/expectation-framework-integration/aggregating-failures) for more detail.

  Note: The implementation of `aggregate_failures` uses a thread-local variable, which means that if you have an expectation failure in another thread, it'll abort like normal.

  Scenario: Multiple expectation failures within `aggregate_failures` are all reported
    Given a file named "spec/aggregated_failure_spec.rb" with:
      """ruby
      require 'rspec/expectations'
      include RSpec::Matchers

      Response = Struct.new(:status, :headers, :body)
      response = Response.new(404, { "Content-Type" => "text/plain" }, "Not Found")

      begin
        aggregate_failures "testing response" do
          expect(response.status).to eq(200)
          expect(response.headers["Content-Type"]).to eq("application/json")
          expect(response.body).to eq('{"message":"Success"}')
        end
      rescue RSpec::Expectations::MultipleExpectationsNotMetError => e
        puts e.message.gsub(/(:in).+/, '')
        exit(1)
      end
      """
    When I run `ruby spec/aggregated_failure_spec.rb`
    Then it should fail with:
      """
      Got 3 failures from failure aggregation block "testing response":

        1) expected: 200
                got: 404

           (compared using ==)

           spec/aggregated_failure_spec.rb:9

        2) expected: "application/json"
                got: "text/plain"

           (compared using ==)

           spec/aggregated_failure_spec.rb:10

        3) expected: "{"message":"Success"}"
                got: "Not Found"

           (compared using ==)

           spec/aggregated_failure_spec.rb:11
      """
