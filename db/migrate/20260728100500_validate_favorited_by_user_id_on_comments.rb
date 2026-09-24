class ValidateFavoritedByUserIdOnComments < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :comments, column: :favorited_by_user_id
  end
end
