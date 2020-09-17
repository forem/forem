class AddIntdexToRatingVotes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :rating_votes, %i[user_id article_id context], unique: true, algorithm: :concurrently
  end
end
