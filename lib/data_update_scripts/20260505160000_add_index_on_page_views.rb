require "data_update_scripts/data_update_script_base"

class AddIndexOnPageViews < DataUpdateScriptBase
  def run
    # Set statement timeout to 0 for this specific execution thread
    ActiveRecord::Base.connection.execute("SET statement_timeout = 0;")

    # We perform the index creation
    # Using raw execute because add_index with algorithm: :concurrently requires disable_ddl_transaction!
    # which we can't cleanly enforce inside this script wrapper.
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_page_views_on_article_id_and_created_at
      ON page_views (article_id, created_at);
    SQL
  end
end
