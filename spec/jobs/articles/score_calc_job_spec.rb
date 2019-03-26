require "rails_helper"

RSpec.describe Articles::ScoreCalcJob, type: :job do
  include_examples "#enqueues_job", "articles_score_calc", 1
end
