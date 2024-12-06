class <%= role_cname.camelize %> < ActiveRecord::Base
<% if need_table_prefix?(role_cname) %>
  def self.table_name_prefix
    <%= table_prefix(role_cname) %>_
  end
<% end %>
  has_and_belongs_to_many :<%= user_cname.tableize %>, :join_table => :<%= "#{table_name(user_cname, true)}_#{table_name(role_cname, true)}" %>
  belongs_to :resource, :polymorphic => true
  
  scopify
end
