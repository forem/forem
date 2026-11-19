class ValidateEventIdOnArticles < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :articles, :events
  end
end
