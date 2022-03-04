class AddPartialIndexOnReachableToPodcastEpisodes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    return if index_exists?(:podcasts, :reachable)

    add_index :podcasts,
              :reachable,
              where: "reachable = true",
              algorithm: :concurrently
  end

  def down
    return unless index_exists?(:podcasts, :reachable)

    remove_index :podcasts,
                 column: :reachable,
                 algorithm: :concurrently
  end
end
