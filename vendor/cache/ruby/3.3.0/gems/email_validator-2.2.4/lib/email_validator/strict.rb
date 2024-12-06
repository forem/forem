# require this file to enable `:strict` mode by default

require 'email_validator'
EmailValidator.default_options[:mode] = :strict
