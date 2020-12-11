Feature: Aggregating Failures

  RSpec::Expectations provides [`aggregate_failures`](https://relishapp.com/rspec/rspec-expectations/docs/aggregating-failures), an API that allows you to group a set of expectations and see all the failures at once, rather than it aborting on the first failure. RSpec::Core improves on this feature in a couple of ways:

    * RSpec::Core provides much better failure output, adding code snippets and backtraces to the sub-failures, just like it does for any normal failure.
    * RSpec::Core provides [metadata](../metadata/user-defined-metadata) integration for this feature. Each example that is tagged with `:aggregate_failures` will be wrapped in an `aggregate_failures` block. You can also use `config.define_derived_metadata` to apply this to every example automatically.

  The metadata form is quite convenient, but may not work well for end-to-end tests that have multiple distinct steps. For example, consider a spec for an HTTP client workflow that (1) makes a request, (2) expects a redirect, (3) follows the redirect, and (4) expects a particular response.  You probably want the `expect(response.status).to be_between(300, 399)` expectation to immediately abort if it fails, because you can't perform the next step (following the redirect) if that is not satisfied. For these situations, we encourage you to use the `aggregate_failures` block form to wrap each set of expectations that represents a distinct step in the test workflow.

  Background:
    Given a file named "lib/client.rb" with:
      """ruby
      Response = Struct.new(:status, :headers, :body)

      class Client
        def self.make_request(url='/')
          Response.new(404, { "Content-Type" => "text/plain" }, "Not Found")
        end
      end
      """

  @skip-when-diff-lcs-1.3
  Scenario: Use `aggregate_failures` block form
    Given a file named "spec/use_block_form_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        after do
          # this should be appended to failure list
          expect(false).to be(true), "after hook failure"
        end

        around do |ex|
          ex.run
          # this should also be appended to failure list
          expect(false).to be(true), "around hook failure"
        end

        it "returns a successful response" do
          response = Client.make_request

          aggregate_failures "testing response" do
            expect(response.status).to eq(200)
            expect(response.headers).to include("Content-Type" => "application/json")
            expect(response.body).to eq('{"message":"Success"}')
          end
        end
      end
      """
    When I run `rspec spec/use_block_form_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Got 3 failures from failure aggregation block "testing response".
                # ./spec/use_block_form_spec.rb:18
                # ./spec/use_block_form_spec.rb:10

                1.1.1) Failure/Error: expect(response.status).to eq(200)

                         expected: 200
                              got: 404

                         (compared using ==)
                       # ./spec/use_block_form_spec.rb:19

                1.1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                         Diff:
                         @@ -1 +1 @@
                         -"Content-Type" => "application/json",
                         +"Content-Type" => "text/plain",
                       # ./spec/use_block_form_spec.rb:20

                1.1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                         expected: "{\"message\":\"Success\"}"
                              got: "Not Found"

                         (compared using ==)
                       # ./spec/use_block_form_spec.rb:21

           1.2) Failure/Error: expect(false).to be(true), "after hook failure"
                  after hook failure
                # ./spec/use_block_form_spec.rb:6
                # ./spec/use_block_form_spec.rb:10

           1.3) Failure/Error: expect(false).to be(true), "around hook failure"
                  around hook failure
                # ./spec/use_block_form_spec.rb:12
      """

  @skip-when-diff-lcs-1.4
  Scenario: Use `aggregate_failures` block form
    Given a file named "spec/use_block_form_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        after do
          # this should be appended to failure list
          expect(false).to be(true), "after hook failure"
        end

        around do |ex|
          ex.run
          # this should also be appended to failure list
          expect(false).to be(true), "around hook failure"
        end

        it "returns a successful response" do
          response = Client.make_request

          aggregate_failures "testing response" do
            expect(response.status).to eq(200)
            expect(response.headers).to include("Content-Type" => "application/json")
            expect(response.body).to eq('{"message":"Success"}')
          end
        end
      end
      """
    When I run `rspec spec/use_block_form_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Got 3 failures from failure aggregation block "testing response".
                # ./spec/use_block_form_spec.rb:18
                # ./spec/use_block_form_spec.rb:10

                1.1.1) Failure/Error: expect(response.status).to eq(200)

                         expected: 200
                              got: 404

                         (compared using ==)
                       # ./spec/use_block_form_spec.rb:19

                1.1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                         Diff:
                         @@ -1,2 +1,2 @@
                         -"Content-Type" => "application/json",
                         +"Content-Type" => "text/plain",
                       # ./spec/use_block_form_spec.rb:20

                1.1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                         expected: "{\"message\":\"Success\"}"
                              got: "Not Found"

                         (compared using ==)
                       # ./spec/use_block_form_spec.rb:21

           1.2) Failure/Error: expect(false).to be(true), "after hook failure"
                  after hook failure
                # ./spec/use_block_form_spec.rb:6
                # ./spec/use_block_form_spec.rb:10

           1.3) Failure/Error: expect(false).to be(true), "around hook failure"
                  around hook failure
                # ./spec/use_block_form_spec.rb:12
      """

  Scenario: Use `:aggregate_failures` metadata
    Given a file named "spec/use_metadata_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        it "follows a redirect", :aggregate_failures do
          response = Client.make_request

          expect(response.status).to eq(302)
          expect(response.body).to eq('{"message":"Redirect"}')

          redirect_response = Client.make_request(response.headers.fetch('Location'))

          expect(redirect_response.status).to eq(200)
          expect(redirect_response.body).to eq('{"message":"OK"}')
        end
      end
      """
    When I run `rspec spec/use_metadata_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client follows a redirect
           Got 2 failures and 1 other error:

           1.1) Failure/Error: expect(response.status).to eq(302)

                  expected: 302
                       got: 404

                  (compared using ==)
                # ./spec/use_metadata_spec.rb:7

           1.2) Failure/Error: expect(response.body).to eq('{"message":"Redirect"}')

                  expected: "{\"message\":\"Redirect\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/use_metadata_spec.rb:8

           1.3) Failure/Error: redirect_response = Client.make_request(response.headers.fetch('Location'))
                KeyError:
                  key not found: "Location"
                # ./spec/use_metadata_spec.rb:10
                # ./spec/use_metadata_spec.rb:10
      """

  @skip-when-diff-lcs-1.3
  Scenario: Enable failure aggregation globally using `define_derived_metadata`
    Given a file named "spec/enable_globally_spec.rb" with:
      """ruby
      require 'client'

      RSpec.configure do |c|
        c.define_derived_metadata do |meta|
          meta[:aggregate_failures] = true
        end
      end

      RSpec.describe Client do
        it "returns a successful response" do
          response = Client.make_request

          expect(response.status).to eq(200)
          expect(response.headers).to include("Content-Type" => "application/json")
          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/enable_globally_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/enable_globally_spec.rb:13

           1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                  expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                  Diff:
                  @@ -1 +1 @@
                  -"Content-Type" => "application/json",
                  +"Content-Type" => "text/plain",
                # ./spec/enable_globally_spec.rb:14

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/enable_globally_spec.rb:15
      """

  @skip-when-diff-lcs-1.4
  Scenario: Enable failure aggregation globally using `define_derived_metadata`
    Given a file named "spec/enable_globally_spec.rb" with:
      """ruby
      require 'client'

      RSpec.configure do |c|
        c.define_derived_metadata do |meta|
          meta[:aggregate_failures] = true
        end
      end

      RSpec.describe Client do
        it "returns a successful response" do
          response = Client.make_request

          expect(response.status).to eq(200)
          expect(response.headers).to include("Content-Type" => "application/json")
          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/enable_globally_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/enable_globally_spec.rb:13

           1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                  expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                  Diff:
                  @@ -1,2 +1,2 @@
                  -"Content-Type" => "application/json",
                  +"Content-Type" => "text/plain",
                # ./spec/enable_globally_spec.rb:14

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/enable_globally_spec.rb:15
      """

  @skip-when-diff-lcs-1.3
  Scenario: Nested failure aggregation works
    Given a file named "spec/nested_failure_aggregation_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        it "returns a successful response", :aggregate_failures do
          response = Client.make_request

          expect(response.status).to eq(200)

          aggregate_failures "testing headers" do
            expect(response.headers).to include("Content-Type" => "application/json")
            expect(response.headers).to include("Content-Length" => "21")
          end

          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/nested_failure_aggregation_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/nested_failure_aggregation_spec.rb:7

           1.2) Got 2 failures from failure aggregation block "testing headers".
                # ./spec/nested_failure_aggregation_spec.rb:9

                1.2.1) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                         Diff:
                         @@ -1 +1 @@
                         -"Content-Type" => "application/json",
                         +"Content-Type" => "text/plain",
                       # ./spec/nested_failure_aggregation_spec.rb:10

                1.2.2) Failure/Error: expect(response.headers).to include("Content-Length" => "21")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Length" => "21"}
                         Diff:
                         @@ -1 +1 @@
                         -"Content-Length" => "21",
                         +"Content-Type" => "text/plain",
                       # ./spec/nested_failure_aggregation_spec.rb:11

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/nested_failure_aggregation_spec.rb:14
      """

  @skip-when-diff-lcs-1.4
  Scenario: Nested failure aggregation works
    Given a file named "spec/nested_failure_aggregation_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        it "returns a successful response", :aggregate_failures do
          response = Client.make_request

          expect(response.status).to eq(200)

          aggregate_failures "testing headers" do
            expect(response.headers).to include("Content-Type" => "application/json")
            expect(response.headers).to include("Content-Length" => "21")
          end

          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/nested_failure_aggregation_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Client returns a successful response
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/nested_failure_aggregation_spec.rb:7

           1.2) Got 2 failures from failure aggregation block "testing headers".
                # ./spec/nested_failure_aggregation_spec.rb:9

                1.2.1) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                         Diff:
                         @@ -1,2 +1,2 @@
                         -"Content-Type" => "application/json",
                         +"Content-Type" => "text/plain",
                       # ./spec/nested_failure_aggregation_spec.rb:10

                1.2.2) Failure/Error: expect(response.headers).to include("Content-Length" => "21")
                         expected {"Content-Type" => "text/plain"} to include {"Content-Length" => "21"}
                         Diff:
                         @@ -1,2 +1,2 @@
                         -"Content-Length" => "21",
                         +"Content-Type" => "text/plain",
                       # ./spec/nested_failure_aggregation_spec.rb:11

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/nested_failure_aggregation_spec.rb:14
      """

  Scenario: Mock expectation failures are aggregated as well
    Given a file named "spec/mock_expectation_failure_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe "Aggregating Failures", :aggregate_failures do
        it "has a normal expectation failure and a message expectation failure" do
          client = double("Client")
          expect(client).to receive(:put).with("updated data")
          allow(client).to receive(:get).and_return(Response.new(404, {}, "Not Found"))

          response = client.get
          expect(response.status).to eq(200)
        end
      end
      """
    When I run `rspec spec/mock_expectation_failure_spec.rb`
    Then it should fail and list all the failures:
      """
      Failures:

        1) Aggregating Failures has a normal expectation failure and a message expectation failure
           Got 2 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/mock_expectation_failure_spec.rb:10

           1.2) Failure/Error: expect(client).to receive(:put).with("updated data")
                  (Double "Client").put("updated data")
                      expected: 1 time with arguments: ("updated data")
                      received: 0 times
                # ./spec/mock_expectation_failure_spec.rb:6

      """

  @skip-when-diff-lcs-1.3
  Scenario: Pending integrates properly with aggregated failures
    Given a file named "spec/pending_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        it "returns a successful response", :aggregate_failures do
          pending "Not yet ready"
          response = Client.make_request

          expect(response.status).to eq(200)
          expect(response.headers).to include("Content-Type" => "application/json")
          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/pending_spec.rb`
    Then it should pass and list all the pending examples:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) Client returns a successful response
           # Not yet ready
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/pending_spec.rb:8

           1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                  expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                  Diff:
                  @@ -1 +1 @@
                  -"Content-Type" => "application/json",
                  +"Content-Type" => "text/plain",
                # ./spec/pending_spec.rb:9

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/pending_spec.rb:10
      """

  @skip-when-diff-lcs-1.4
  Scenario: Pending integrates properly with aggregated failures
    Given a file named "spec/pending_spec.rb" with:
      """ruby
      require 'client'

      RSpec.describe Client do
        it "returns a successful response", :aggregate_failures do
          pending "Not yet ready"
          response = Client.make_request

          expect(response.status).to eq(200)
          expect(response.headers).to include("Content-Type" => "application/json")
          expect(response.body).to eq('{"message":"Success"}')
        end
      end
      """
    When I run `rspec spec/pending_spec.rb`
    Then it should pass and list all the pending examples:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) Client returns a successful response
           # Not yet ready
           Got 3 failures:

           1.1) Failure/Error: expect(response.status).to eq(200)

                  expected: 200
                       got: 404

                  (compared using ==)
                # ./spec/pending_spec.rb:8

           1.2) Failure/Error: expect(response.headers).to include("Content-Type" => "application/json")
                  expected {"Content-Type" => "text/plain"} to include {"Content-Type" => "application/json"}
                  Diff:
                  @@ -1,2 +1,2 @@
                  -"Content-Type" => "application/json",
                  +"Content-Type" => "text/plain",
                # ./spec/pending_spec.rb:9

           1.3) Failure/Error: expect(response.body).to eq('{"message":"Success"}')

                  expected: "{\"message\":\"Success\"}"
                       got: "Not Found"

                  (compared using ==)
                # ./spec/pending_spec.rb:10
      """
