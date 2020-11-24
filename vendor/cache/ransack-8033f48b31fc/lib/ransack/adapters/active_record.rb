require 'ransack/adapters/active_record/base'

ActiveSupport.on_load(:active_record) do
  extend Ransack::Adapters::ActiveRecord::Base

  Ransack::SUPPORTS_ATTRIBUTE_ALIAS =
  begin
    ActiveRecord::Base.respond_to?(:attribute_aliases)
  rescue NameError
    false
  end
end

require 'ransack/adapters/active_record/context'
