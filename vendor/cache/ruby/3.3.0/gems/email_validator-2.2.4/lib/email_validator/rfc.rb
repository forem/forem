# require this file to enable `:rfc` mode by default

require 'email_validator'
EmailValidator.default_options[:mode] = :rfc
