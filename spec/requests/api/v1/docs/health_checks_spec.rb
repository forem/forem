require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::HealthChecks" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }

  describe "GET /health_checks/app" do
    path "/api/health_checks/app" do
      get "Check app health" do
        tags "health_checks"
        security []
        description "Basic application liveness check.

### Usage Guidance:
- Verifies that the Rails application process is running and responding to requests.
- Does not check database or cache connectivity.
- Typically used by load balancers, container orchestrators (like Kubernetes), or uptime checkers to verify container health."
        produces "application/json"
        parameter name: :"health-check-token", in: :header, required: false,
                  description: "Access token required if token-based security is enabled in settings for health checks.",
                  schema: { type: :string }

        response "200", "successful" do
          let(:"health-check-token") { Settings::General.health_check_token }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /health_checks/database" do
    path "/api/health_checks/database" do
      get "Check database connection" do
        tags "health_checks"
        security []
        description "Database connection health check.

### Usage Guidance:
- Verifies that the application can successfully query the primary PostgreSQL database.
- Used to monitor database pool status and connection health."
        produces "application/json"
        parameter name: :"health-check-token", in: :header, required: false,
                  description: "Access token required if token-based security is enabled in settings for health checks.",
                  schema: { type: :string }

        response "200", "successful" do
          let(:"health-check-token") { Settings::General.health_check_token }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /health_checks/cache" do
    path "/api/health_checks/cache" do
      get "Check cache connection" do
        tags "health_checks"
        security []
        description "Cache connection health check.

### Usage Guidance:
- Verifies that the application can successfully ping the Redis cache instance.
- Used to monitor cache and background worker queue connection health."
        produces "application/json"
        parameter name: :"health-check-token", in: :header, required: false,
                  description: "Access token required if token-based security is enabled in settings for health checks.",
                  schema: { type: :string }

        before do
          allow(Redis).to receive(:new).and_return(double(ping: "PONG"))
        end

        response "200", "successful" do
          let(:"health-check-token") { Settings::General.health_check_token }
          add_examples
          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
