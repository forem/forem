require 'yard'

module YARD::Handlers::Ruby::ActiveRecord
end

YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/../templates'

root = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << root unless $LOAD_PATH.include? root

require 'yard-activerecord/fields/create_table_handler'
require 'yard-activerecord/fields/define_handler'
require 'yard-activerecord/fields/field_handler'

require 'yard-activerecord/associations/belongs_to_handler'
require 'yard-activerecord/associations/has_one_handler'
require 'yard-activerecord/associations/has_many_handler'
require 'yard-activerecord/associations/has_and_belongs_to_many_handler'

require 'yard-activerecord/delegations/delegate_handler'

require 'yard-activerecord/scopes/scope_handler'
require 'yard-activerecord/validations/validates_handler'
