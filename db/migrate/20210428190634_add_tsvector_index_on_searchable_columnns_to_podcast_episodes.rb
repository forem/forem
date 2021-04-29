class AddTsvectorIndexOnSearchableColumnnsToPodcastEpisodes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    query = <<-SQL
      ((((
        to_tsvector('simple'::regconfig, COALESCE(body, ''::text)) ||
        to_tsvector('simple'::regconfig, COALESCE((subtitle)::text, ''::text))) ||
        to_tsvector('simple'::regconfig, COALESCE((title)::text, ''::text
      )))))
    SQL

    unless index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_search_fields_as_tsvector)
      add_index :podcast_episodes,
                query,
                using: :gin,
                name: :index_podcast_episodes_on_search_fields_as_tsvector,
                algorithm: :concurrently
    end
    
    # Removing unused existing indexes
    if index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_body_as_tsvector)
      remove_index :podcast_episodes,
                   name: :index_podcast_episodes_on_body_as_tsvector,
                   algorithm: :concurrently
    end

    if index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_subtitle_as_tsvector)
      remove_index :podcast_episodes,
                   name: :index_podcast_episodes_on_subtitle_as_tsvector,
                   algorithm: :concurrently
    end

    if index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_title_as_tsvector)
      remove_index :podcast_episodes,
                   name: :index_podcast_episodes_on_title_as_tsvector,
                   algorithm: :concurrently
    end

  end

  def down
    if index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_search_fields_as_tsvector)
      remove_index :podcast_episodes,
                   name: :index_podcast_episodes_on_search_fields_as_tsvector,
                   algorithm: :concurrently
    end

    # Add back old unused indexes
    unless index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_body_as_tsvector)
      add_index :podcast_episodes,
                "to_tsvector('simple'::regconfig, COALESCE((body)::text, ''::text))",
                using: :gin,
                name: :index_podcast_episodes_on_body_as_tsvector,
                algorithm: :concurrently
    end

    unless index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_subtitle_as_tsvector)
      add_index :podcast_episodes,
                "to_tsvector('simple'::regconfig, COALESCE((subtitle)::text, ''::text))",
                using: :gin,
                name: :index_podcast_episodes_on_subtitle_as_tsvector,
                algorithm: :concurrently
    end

    unless index_name_exists?(:podcast_episodes, :index_podcast_episodes_on_title_as_tsvector)
      add_index :podcast_episodes,
                "to_tsvector('simple'::regconfig, COALESCE((title)::text, ''::text))",
                using: :gin,
                name: :index_podcast_episodes_on_title_as_tsvector,
                algorithm: :concurrently
    end
  end
end
