class AddTsvectorUpdateTriggerToArticlesTsv < ActiveRecord::Migration[6.0]
  def up
    safety_assured do
      execute <<-SQL
        CREATE TRIGGER tsv_tsvector_update
        BEFORE INSERT OR UPDATE ON articles
        FOR EACH ROW EXECUTE FUNCTION
        tsvector_update_trigger(tsv, 'pg_catalog.simple', body_markdown, cached_tag_list, title);
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        DROP TRIGGER tsv_tsvector_update
        ON articles;
      SQL
    end
  end
end
