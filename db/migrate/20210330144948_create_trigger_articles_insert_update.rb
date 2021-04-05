# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerArticlesInsertUpdate < ActiveRecord::Migration[6.0]
  def up
    create_trigger("tsv_tsvector_update", :generated => true, :compatibility => 1).
        on("articles").
        name("tsv_tsvector_update").
        before(:insert, :update) do
      <<~SQL
        NEW.tsv := (
          SELECT to_tsvector('simple'::regconfig, unaccent(body_markdown)) ||
                 to_tsvector('simple'::regconfig, unaccent(cached_tag_list)) ||
                 to_tsvector('simple'::regconfig, unaccent(title)) ||
                 to_tsvector('simple'::regconfig, unaccent(coalesce(organizations.name, ''))) ||
                 to_tsvector('simple'::regconfig, unaccent(coalesce(users.name, ''))) ||
                 to_tsvector('simple'::regconfig, unaccent(coalesce(users.username, ''))) AS tsvector
          FROM articles
          LEFT OUTER JOIN organizations ON organizations.id = articles.organization_id
          LEFT OUTER JOIN users ON users.id = articles.user_id
          WHERE articles.id = NEW.id
        );
      SQL
    end
  end

  def down
    drop_trigger("tsv_tsvector_update", "articles", :generated => true)
  end
end
