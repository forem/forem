class AddIndexesToPageRedirect < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:page_redirects, :old_slug)
      add_index :page_redirects, :old_slug, unique: true, algorithm: :concurrently
    end

    unless index_exists?(:page_redirects, :new_slug)
      add_index :page_redirects, :new_slug, algorithm: :concurrently
    end

    unless index_exists?(:page_redirects, %i[old_slug new_slug])
      add_index :page_redirects, %i[old_slug new_slug], unique: true, algorithm: :concurrently
    end

    unless index_exists?(:page_redirects, :version)
      add_index :page_redirects, :version, algorithm: :concurrently
    end

    unless index_exists?(:page_redirects, :overridden)
      add_index :page_redirects, :overridden, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:page_redirects, :old_slug)
      remove_index :page_redirects, column: :old_slug, algorithm: :concurrently
    end

    if index_exists?(:page_redirects, :new_slug)
      remove_index :page_redirects, column: :new_slug, algorithm: :concurrently
    end

    if index_exists?(:page_redirects, %i[old_slug new_slug])
      remove_index :page_redirects, column: %i[old_slug new_slug], algorithm: :concurrently
    end

    if index_exists?(:page_redirects, :version)
      remove_index :page_redirects, column: :version, algorithm: :concurrently
    end

    if index_exists?(:page_redirects, :overridden)
      remove_index :page_redirects, column: :overriden, algorithm: :concurrently
    end
  end
end
