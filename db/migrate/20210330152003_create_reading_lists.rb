class CreateReadingLists < ActiveRecord::Migration[6.0]
  def change
    create_view :reading_lists, materialized: true
  end
end
