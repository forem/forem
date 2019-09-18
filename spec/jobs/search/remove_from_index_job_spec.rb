require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Search::RemoveFromIndexJob, type: :job do
  include_examples "#enqueues_job", "search_remove_from_index",
                   "searchables_#{Rails.env}", "users-456"
end
