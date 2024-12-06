# Based on work from http://thelucid.com/2010/01/08/sexy-validation-in-edge-rails-rails-3/

# EmailValidator class
class EmailValidator < ActiveModel::EachValidator
  # rubocop:disable Style/ClassVars
  @@default_options = {
    :allow_nil => false,
    :domain => nil,
    :require_fqdn => nil,
    :mode => :loose
  }
  # rubocop:enable Style/ClassVars

  # EmailValidator::Error class
  class Error < StandardError
    def initialize(msg = 'EmailValidator error')
      super
    end
  end

  class << self
    def default_options
      @@default_options
    end

    def valid?(value, options = {})
      options = parse_options(options)
      return true if value.nil? && options[:allow_nil] == true
      return false if value.nil?
      # quickly fail if domain is required but doesn't match
      return false unless options[:domain].nil? || value[/^.*@#{regexp_safe_domain(options)}$/]
      !!(value =~ regexp(options))
    end

    def invalid?(value, options = {})
      !valid?(value, options)
    end

    # Refs:
    #  https://tools.ietf.org/html/rfc2822 : 3.2. Lexical Tokens, 3.4.1. Addr-spec specification
    #  https://tools.ietf.org/html/rfc5321 : 4.1.2.  Command Argument Syntax
    def regexp(options = {})
      options = parse_options(options)
      case options[:mode]
      when :loose
        loose_regexp(options)
      when :rfc
        rfc_regexp(options)
      when :strict
        options[:require_fqdn] = true
        strict_regexp(options)
      else
        fail EmailValidator::Error, "Validation mode '#{options[:mode]}' is not supported by EmailValidator"
      end
    end

    protected

    def loose_regexp(options = {})
      return /\A[^\s]+@[^\s]+\z/ if options[:domain].nil?
      /\A[^\s]+@#{domain_part_pattern(options)}\z/
    end

    def strict_regexp(options = {})
      /\A(?>#{local_part_pattern})@#{domain_part_pattern(options)}\z/i
    end

    def rfc_regexp(options = {})
      /\A(?>#{local_part_pattern})(?:@#{domain_part_pattern(options)})?\z/i
    end

    def alpha
      '[[:alpha:]]'
    end

    def alnum
      '[[:alnum:]]'
    end

    def alnumhy
      "(?:#{alnum}|-)"
    end

    def ipv4
      '\d{1,3}(?:\.\d{1,3}){3}'
    end

    def ipv6
      # only supporting full IPv6 addresses right now
      'IPv6:[[:xdigit:]]{1,4}(?::[[:xdigit:]]{1,4}){7}'
    end

    def address_literal
      "\\[(?:#{ipv4}|#{ipv6})\\]"
    end

    def host_label_pattern
      "#{label_is_correct_length}" \
      "#{alnum}(?:#{alnumhy}{,61}#{alnum})?"
    end

    # splitting this up into separate regex pattern for performance; let's not
    # try the "contains" pattern unless we have to
    def domain_label_pattern
      "#{host_label_pattern}\\.#{tld_label_pattern}"
    end

    # While, techincally, TLDs can be numeric-only, this is not allowed by ICANN
    # Ref: ICANN Application Guidebook for new TLDs (June 2012)
    #      says the following starting at page 64:
    #
    #      > The ASCII label must consist entirely of letters (alphabetic characters a-z)
    #
    #      -- https://newgtlds.icann.org/en/applicants/agb/guidebook-full-04jun12-en.pdf
    def tld_label_pattern
      "#{alpha}{1,64}"
    end

    def label_is_correct_length
      '(?=[^.]{1,63}(?:\.|$))'
    end

    def domain_part_is_correct_length
      '(?=.{1,255}$)'
    end

    def atom_char
      # The `atext` spec
      # We are looking at this without whitespace; no whitespace support here
      "[-#{alpha}#{alnum}+_!\"'#$%^&*{}/=?`|~]"
    end

    def local_part_pattern
      # the `dot-atom-text` spec, but with a 64 character limit
      "#{atom_char}(?:\\.?#{atom_char}){,63}"
    end

    def domain_part_pattern(options)
      return regexp_safe_domain(options) unless options[:domain].nil?
      return fqdn_pattern if options[:require_fqdn]
      "#{domain_part_is_correct_length}(?:#{address_literal}|(?:#{host_label_pattern}\\.)*#{tld_label_pattern})"
    end

    def fqdn_pattern
      "(?=.{1,255}$)(?:#{host_label_pattern}\\.)*#{domain_label_pattern}"
    end

    private

    def parse_options(options)
      # `:strict` mode enables `:require_fqdn`, unless it is already explicitly disabled
      options[:require_fqdn] = true if options[:require_fqdn].nil? && options[:mode] == :strict
      default_options.merge(options)
    end

    def regexp_safe_domain(options)
      options[:domain].sub(/\./, '\.')
    end
  end

  def validate_each(record, attribute, value)
    options = @@default_options.merge(self.options)
    record.errors.add(attribute, options[:message] || :invalid) unless self.class.valid?(value, options)
  end
end
