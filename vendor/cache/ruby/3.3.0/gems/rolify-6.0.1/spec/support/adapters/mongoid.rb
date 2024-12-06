load File.dirname(__FILE__) + '/utils/mongoid.rb'

load_mongoid_config

begin
  Mongo::Logger.logger.level = ::Logger::FATAL
rescue NameError
end

::Mongoid::Document.module_eval do
  def self.included(base)
    base.extend Rolify
  end
end

Rolify.use_mongoid

# Standard user and role classes
class User
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }

  rolify

  field :login, :type => String
end

# Standard user and role classes
class StrictUser
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  rolify strict: true

  field :login, :type => String
end

class Role
  include Mongoid::Document
  has_and_belongs_to_many :users
  has_and_belongs_to_many :strict_users
  belongs_to :resource, :polymorphic => true

  field :name, :type => String
  index(
    {
      :name => 1,
      :resource_type => 1,
      :resource_id => 1
    },
    { :unique => true }
  )

  scopify
end

# Resourcifed and rolifed at the same time
class HumanResource
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  resourcify :resources
  rolify

  field :login, :type => String
end

#class Power
#  include Mongoid::Document
#  has_and_belongs_to_many :human_resources
#  belongs_to :resource, :polymorphic => true
#  scopify
#
#  field :name, :type => String
#  index(
#    {
#      :name => 1,
#      :resource_type => 1,
#      :resource_id => 1
#    },
#    { :unique => true }
#  )
#end

# Custom role and class names
class Customer
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  rolify :role_cname => "Privilege"

  field :login, :type => String
end

class Privilege
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  has_and_belongs_to_many :customers
  belongs_to :resource, :polymorphic => true
  scopify

  field :name, :type => String
  index(
    {
      :name => 1,
      :resource_type => 1,
      :resource_id => 1
    },
    { :unique => true }
  )
end

# Namespaced models
module Admin
  class Moderator
    include Mongoid::Document
    default_scope -> { order_by id: 'asc' }
    rolify :role_cname => "Admin::Right"

    field :login, :type => String
  end

  class Right
    include Mongoid::Document
    default_scope -> { order_by id: 'asc' }
    has_and_belongs_to_many :moderators, :class_name => 'Admin::Moderator'
    belongs_to :resource, :polymorphic => true
    scopify

    field :name, :type => String
    index(
      {
        :name => 1,
        :resource_type => 1,
        :resource_id => 1
      },
      { :unique => true }
    )
  end
end

# Resources classes
class Forum
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  #resourcify done during specs setup to be able to use custom user classes

  field :name, :type => String
end

class Group
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  #resourcify done during specs setup to be able to use custom user classes

  field :name, :type => String
  field :parent_id, :type => Integer

  def subgroups
    Group.in(:parent_id => _id)
  end
end

class Team
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
  #resourcify done during specs setup to be able to use custom user classes

  field :team_code, :type => Integer
  field :name, :type => String
end

class Organization
  include Mongoid::Document
  default_scope -> { order_by id: 'asc' }
end

class Company < Organization

end
