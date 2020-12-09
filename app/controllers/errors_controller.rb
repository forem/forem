class ErrorsController < ApplicationController
  GITHUB_BUG_REPORT_DOMAINS = ["dev.to", "forem.dev"].freeze
  GITHUB_BUG_REPORT_URL = "https://github.com/forem/forem/issues/new?template=bug_report.md".freeze

  # HTTP 404 - Not Found - https://httpstatuses.com/400
  def not_found
    render status: :not_found
  end

  # HTTP 422 - Unprocessable Entity - https://httpstatuses.com/422
  def unprocessable_entity
    render status: :unprocessable_entity
  end

  # HTTP 500 - Internal Server Error - https://httpstatuses.com/500
  def internal_server_error
    @github_bug_report_url = GITHUB_BUG_REPORT_URL
    @display_github_bug_report_url = SiteConfig.app_domain.in?(GITHUB_BUG_REPORT_DOMAINS)

    render status: :internal_server_error
  end

  # HTTP 503 - Service Unavailable - https://httpstatuses.com/503
  def service_unavailable
    render status: :service_unavailable
  end
end
