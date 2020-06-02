module RolifyExtension
  def add_role(role_name, resource = nil)
    super(role_name, resource = nil)
    success = false
    Rails.logger.error("role_name: #{role_name}, resource: #{resource}")
    begin
      Timeout.timeout 5 do
        until success
          self.roles.each { |role| success = true if role.name == role_name.to_s }
        end
      end
    rescue
      Rails.logger.error("In RolifyExtension rescue. self.roles: #{self.roles}")
    end
  end
end

module Rolify
  module Role
    prepend RolifyExtension
  end
end