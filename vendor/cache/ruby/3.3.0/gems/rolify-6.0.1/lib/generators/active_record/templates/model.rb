  has_and_belongs_to_many :<%= user_class.table_name %>, :join_table => :<%= join_table %>
  <% if Rails::VERSION::MAJOR < 5 %>
  belongs_to :resource,
             :polymorphic => true
  <% else %>
  belongs_to :resource,
             :polymorphic => true,
             :optional => true
  <% end %>

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify
