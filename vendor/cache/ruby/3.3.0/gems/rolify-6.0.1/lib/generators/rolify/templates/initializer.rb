Rolify.configure<%= "(\"#{class_name.camelize.to_s}\")" if class_name != "Role" %> do |config|
  # By default ORM adapter is ActiveRecord. uncomment to use mongoid
  <%= "# " if options.orm == :active_record || !options.orm %>config.use_mongoid

  # Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
  # config.use_dynamic_shortcuts
  
  # Configuration to remove roles from database once the last resource is removed. Default is: true
  # config.remove_role_if_empty = false
end
