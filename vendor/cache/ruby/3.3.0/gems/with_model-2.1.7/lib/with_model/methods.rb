# frozen_string_literal: true

module WithModel
  # Extended into all ActiveRecord models created by with_model.
  module Methods
    # Since model classes not created by with_model won't have this
    # method, one should instead test `respond_to?(:with_model?)`.
    def with_model?
      true
    end
  end
end
