class RemoveSuperfluousIndexesPart1 < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    # covered by index_articles_on_slug_and_user_id
    if index_exists?(:articles, :slug)
      remove_index :articles, column: :slug, algorithm: :concurrently
    end

    # covered by index_rating_votes_on_user_id_and_article_id_and_context
    if index_exists?(:rating_votes, :user_id)
      remove_index :rating_votes, column: :user_id, algorithm: :concurrently
    end

    # covered by idx_pins_on_pinnable_id_profile_id_profile_type_pinnable_type
    if index_exists?(:profile_pins, :pinnable_id)
      remove_index :profile_pins, column: :pinnable_id, algorithm: :concurrently
    end

    # covered by index_reactions_on_reactable_id_and_reactable_type
    if index_exists?(:reactions, :reactable_id)
      remove_index :reactions, column: :reactable_id, algorithm: :concurrently
    end

    # covered by index_reactions_on_user_id_reactable_id_reactable_type_category
    if index_exists?(:reactions, :user_id)
      remove_index :reactions, column: :user_id, algorithm: :concurrently
    end
  end

  def down
    unless index_exists?(:articles, :slug)
      add_index :articles, :slug, algorithm: :concurrently
    end

    unless index_exists?(:rating_votes, :user_id)
      add_index :rating_votes, :user_id, algorithm: :concurrently
    end

    unless index_exists?(:profile_pins, :pinnable_id)
      add_index :profile_pins, :pinnable_id, algorithm: :concurrently
    end

    unless index_exists?(:reactions, :reactable_id)
      add_index :reactions, :reactable_id, algorithm: :concurrently
    end

    unless index_exists?(:reactions, :user_id)
      add_index :reactions, :user_id, algorithm: :concurrently
    end
  end
end
