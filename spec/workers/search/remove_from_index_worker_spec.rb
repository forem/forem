require "rails_helper"
# require "jobs/shared_examples/enqueues_on_correct_queue"

RSpec.describe Search::RemoveFromIndexWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "search_remove_from_index",
                   "searchables_#{Rails.env}", "users-456"
end
