require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe HtmlVariantSuccessCreateJob, type: :job do
  include_examples "#enqueues_job", "html_variant_success_create", [{ html_variant_id: 789, article_id: 456 }]
end
