module RolifyExtension
  def add_role(role_name, resource = nil)
    result = super(role_name, resource = nil)
    success = false
    start = Time.now
    Rails.logger.error("role_name: #{role_name}, resource: #{resource}")
    begin
      Timeout.timeout 5 do
        until success
          self.roles.each { |role| success = true if role.name == role_name.to_s }
        end
      end
      Rails.logger.error("Took #{(Time.now - start).round(2)}s")
    rescue
      Rails.logger.error("In RolifyExtension rescue. role_name: #{role_name}, resource: #{resource}")
    end
    result
  end
end

module Rolify
  module Role
    prepend RolifyExtension
  end
end
