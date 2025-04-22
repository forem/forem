module Ahoy
  #  @note When we destroy the related user, it's using dependent:
  #        :delete for the relationship.  That means no before/after
  #        destroy callbacks will be called on this object.
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    has_many :events, class_name: "Ahoy::Event", dependent: :destroy
    belongs_to :user, optional: true
    belongs_to :user_visit_context, optional: true

    def self.fast_destroy_old_visits(destroy_before_timestamp = 6.months.ago)
      sql = <<~SQL
        DELETE FROM ahoy_visits
        WHERE ahoy_visits.id IN (
          SELECT ahoy_visits.id
          FROM ahoy_visits
          WHERE ahoy_visits.created_at < ? AND user_id IS NULL
          LIMIT 50000
        )
      SQL
      visit_sql = Visit.sanitize_sql([sql, destroy_before_timestamp])
      BulkSqlDelete.delete_in_batches(visit_sql)
    end
  end
end
