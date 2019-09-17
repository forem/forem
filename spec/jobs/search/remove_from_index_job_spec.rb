require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Search::RemoveFromIndexJob, type: :job do
  include_examples "#enqueues_job", "remove_from_algolia_index",
                   "searchables_#{Rails.env}", "users-456"
end
