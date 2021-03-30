# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerArticlesInsertUpdate < ActiveRecord::Migration[6.0]
  def up
    create_trigger("tsv_tsvector_update", :generated => true, :compatibility => 1).
        on("articles").
        name("tsv_tsvector_update").
        before(:insert, :update) do
      "NEW.tsv := to_tsvector('simple'::regconfig, NEW.body_markdown) || to_tsvector('simple'::regconfig, NEW.cached_tag_list) || to_tsvector('simple'::regconfig, NEW.title); return NEW"
    end
  end

  def down
    drop_trigger("tsv_tsvector_update", "articles", :generated => true)
  end
end
