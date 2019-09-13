require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Reactions::ReactionCreateJob, type: :job do
  include_examples "#enqueues_job", "reaction_create", [{ user_id: 786, reactable_id: 790, reactable_type: "Article", category: "readinglist" }]
end
