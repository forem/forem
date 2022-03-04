# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerArticlesInsertUpdate < ActiveRecord::Migration[6.1]
  def up
    create_trigger("update_reading_list_document", :generated => true, :compatibility => 1).
        on("articles").
        name("update_reading_list_document").
        before(:insert, :update).
        for_each(:row).
        declare("l_org_vector tsvector; l_user_vector tsvector") do
      <<-SQL_ACTIONS
NEW.reading_list_document :=
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.body_markdown, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_tag_list, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_name, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_username, ''))) ||
  to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.title, ''))) ||
  to_tsvector('simple'::regconfig,
    unaccent(
      coalesce(
        array_to_string(
          -- cached_organization is serialized to the DB as a YAML string, we extract only the name attribute
          regexp_match(NEW.cached_organization, 'name: (.*)$', 'n'),
          ' '
        ),
        ''
      )
    )
  );
      SQL_ACTIONS
    end
  end

  def down
    drop_trigger("update_reading_list_document", "articles", :generated => true)
  end
end
