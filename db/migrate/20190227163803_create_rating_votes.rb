class CreateRatingVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :rating_votes do |t|
      t.bigint   :user_id
      t.bigint   :article_id
      t.string   :group
      t.float    :rating
      t.timestamps
    end
    add_index :rating_votes, :user_id
    add_index :rating_votes, :article_id
  end
end
