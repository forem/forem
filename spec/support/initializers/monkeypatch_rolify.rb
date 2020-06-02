module RolifyExtension
  def add_role(role_name, resource = nil)
    super(role_name, resource = nil)
    success = false
    until success
      self.roles.each { |role| success = true if role.name == role_name.to_s }
    end
  end
end

module Rolify
  module Role
    prepend RolifyExtension
  end
end