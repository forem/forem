class <%= role_cname.camelize %>
  include Mongoid::Document
  
  has_and_belongs_to_many :<%= user_cname.tableize %>
  belongs_to :resource, :polymorphic => true
  
  field :name, :type => String

  index({
    :name => 1,
    :resource_type => 1,
    :resource_id => 1
  },
  { :unique => true})
  
  scopify
end
