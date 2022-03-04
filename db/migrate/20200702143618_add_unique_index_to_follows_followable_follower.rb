class AddUniqueIndexToFollowsFollowableFollower < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index(
      :follows,
      %i[followable_id followable_type follower_id follower_type],
      unique: true,
      algorithm: :concurrently,
      name: :index_follows_on_followable_and_follower
    )
  end
end
