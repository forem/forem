module Rolify
  module Configure
    @@dynamic_shortcuts = false
    @@orm = "active_record"
    @@remove_role_if_empty = true

    def configure(*role_cnames)
      return if !sanity_check(role_cnames)
      yield self if block_given?
    end

    def dynamic_shortcuts
      @@dynamic_shortcuts
    end

    def dynamic_shortcuts=(is_dynamic)
      @@dynamic_shortcuts = is_dynamic
    end

    def orm
      @@orm
    end

    def orm=(orm)
      @@orm = orm
    end

    def use_mongoid
      self.orm = "mongoid"
    end

    def use_dynamic_shortcuts
      return if !sanity_check([])
      self.dynamic_shortcuts = true
    end

    def use_defaults
      configure do |config|
        config.dynamic_shortcuts = false
        config.orm = "active_record"
      end
    end

    def remove_role_if_empty=(is_remove)
      @@remove_role_if_empty = is_remove
    end

    def remove_role_if_empty
      @@remove_role_if_empty
    end

    private

    def sanity_check(role_cnames)
      return true if ARGV.reduce(nil) { |acc,arg| arg =~ /assets:/ if acc.nil? } == 0

      role_cnames.each do |role_cname|
        role_class = role_cname.constantize
        if role_class.superclass.to_s == "ActiveRecord::Base" && role_table_missing?(role_class)
          warn "[WARN] table '#{role_cname}' doesn't exist. Did you run the migration? Ignoring rolify config."
          return false
        end
      end
      true
    end

    def role_table_missing?(role_class)
      !role_class.table_exists?
    rescue ActiveRecord::NoDatabaseError
      true
    end

  end
end
