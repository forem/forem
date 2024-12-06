class RolifyCreate<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:<%= table_name %>) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:<%= join_table %>, :id => false) do |t|
      t.references :<%= user_reference %>
      t.references :<%= role_reference %>
    end
    <% if ActiveRecord::Base.connection.class.to_s.demodulize != 'PostgreSQLAdapter' %><%= "\n    " %>add_index(:<%= table_name %>, :name)<% end %>
    add_index(:<%= table_name %>, [ :name, :resource_type, :resource_id ])
    add_index(:<%= join_table %>, [ :<%= user_reference %>_id, :<%= role_reference %>_id ])
  end
end
