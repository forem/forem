load File.dirname(__FILE__) + '/utils/active_record.rb'

extend_rspec_with_activerecord_specific_matchers
establish_connection

ActiveRecord::Base.extend Rolify

load File.dirname(__FILE__) + '/../schema.rb'

# Standard user and role classes
class User < ActiveRecord::Base
  rolify
end

class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  has_and_belongs_to_many :strict_users, :join_table => :strict_users_roles

  belongs_to :resource, :polymorphic => true

  extend Rolify::Adapter::Scopes
end

# Strict user and role classes
class StrictUser < ActiveRecord::Base
  rolify strict: true
end

# Resourcifed and rolifed at the same time
class HumanResource < ActiveRecord::Base
  resourcify :resources
  rolify
end

# Custom role and class names
class Customer < ActiveRecord::Base
  rolify :role_cname => "Privilege"
end

class Privilege < ActiveRecord::Base
  has_and_belongs_to_many :customers, :join_table => :customers_privileges
  belongs_to :resource, :polymorphic => true

  extend Rolify::Adapter::Scopes
end

# Namespaced models
module Admin
  def self.table_name_prefix
    'admin_'
  end

  class Moderator < ActiveRecord::Base
    rolify :role_cname => "Admin::Right", :role_join_table_name => "moderators_rights"
  end

  class Right < ActiveRecord::Base
    has_and_belongs_to_many :moderators, :class_name => "Admin::Moderator", :join_table => "moderators_rights"
    belongs_to :resource, :polymorphic => true

    extend Rolify::Adapter::Scopes
  end
end


# Resources classes
class Forum < ActiveRecord::Base
  #resourcify done during specs setup to be able to use custom user classes
end

class Group < ActiveRecord::Base
  #resourcify done during specs setup to be able to use custom user classes

  def subgroups
    Group.where(:parent_id => id)
  end
end

class Team < ActiveRecord::Base
  #resourcify done during specs setup to be able to use custom user classes
  self.primary_key = "team_code"

  default_scope { order(:team_code) }
end

class Organization < ActiveRecord::Base

end

class Company < Organization

end
