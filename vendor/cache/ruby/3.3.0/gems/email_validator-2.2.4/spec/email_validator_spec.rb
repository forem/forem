require 'spec_helper'

class DefaultUser < TestModel
  validates :email, :email => true
end

class StrictUser < TestModel
  validates :email, :email => { :mode => :strict }
end

class RfcUser < TestModel
  validates :email, :email => { :mode => :rfc }
end

class AllowNilDefaultUser < TestModel
  validates :email, :email => { :allow_nil => true }
end

class AllowNilStrictUser < TestModel
  validates :email, :email => { :allow_nil => true, :mode => :strict }
end

class AllowNilRfcUser < TestModel
  validates :email, :email => { :allow_nil => true, :mode => :rfc }
end

class DisallowNilDefaultUser < TestModel
  validates :email, :email => { :allow_nil => false }
end

class DisallowNilStrictUser < TestModel
  validates :email, :email => { :allow_nil => false, :mode => :strict }
end

class DisallowNilRfcUser < TestModel
  validates :email, :email => { :allow_nil => false, :mode => :rfc }
end

class DomainStrictUser < TestModel
  validates :email, :email => { :domain => 'example.com', :mode => :strict }
end

class DomainRfcUser < TestModel
  validates :email, :email => { :domain => 'example.com', :mode => :rfc }
end

class NonFqdnStrictUser < TestModel
  validates :email, :email => { :require_fqdn => false, :mode => :strict }
end

class NonFqdnRfcUser < TestModel
  validates :email, :email => { :require_fqdn => false, :mode => :rfc }
end

class RequireFqdnWithEmptyDomainUser < TestModel
  validates :email_address, :email => { :require_fqdn => true, :domain => '' }
end

class RequireEmptyDomainStrictUser < TestModel
  validates :email_address, :email => { :require_fqdn => true, :domain => '', :mode => :strict }
end

class RequireEmptyDomainRfcUser < TestModel
  validates :email_address, :email => { :require_fqdn => true, :domain => '', :mode => :rfc }
end

class DefaultUserWithMessage < TestModel
  validates :email_address, :email => { :message => 'is not looking very good!' }
end

RSpec.describe EmailValidator do
  describe 'validation' do
    valid_special_chars = {
      :ampersand => '&',
      :asterisk => '*',
      :backtick => '`',
      :braceleft => '{',
      :braceright => '}',
      :caret => '^',
      :dollar => '$',
      :equals => '=',
      :exclaim => '!',
      :hash => '#',
      :hyphen => '-',
      :percent => '%',
      :plus => '+',
      :pipe => '|',
      :question => '?',
      :quotedouble => '"',
      :quotesingle => "'",
      :slash => '/',
      :tilde => '~',
      :underscore => '_'
    }

    invalid_special_chars = {
      :backslash => '\\',
      :braketleft => '[',
      :braketright => ']',
      :colon => ':',
      :comma => ',',
      :greater => '>',
      :lesser => '<',
      :parenleft => '(',
      :parenright => ')',
      :semicolon => ';'
    }

    valid_includable            = valid_special_chars.merge({ :dot => '.' })
    valid_beginable             = valid_special_chars
    valid_endable               = valid_special_chars
    invalid_includable          = { :at => '@' }
    whitespace                  = { :newline => "\n", :tab => "\t", :carriage_return => "\r", :space => ' ' }
    strictly_invalid_includable = invalid_special_chars
    strictly_invalid_beginable  = strictly_invalid_includable.merge({ :dot => '.' })
    strictly_invalid_endable    = strictly_invalid_beginable
    domain_invalid_beginable    = invalid_special_chars.merge(valid_special_chars)
    domain_invalid_endable      = domain_invalid_beginable
    domain_invalid_includable   = domain_invalid_beginable.reject { |k, _v| k == :hyphen }

    # rubocop:disable Layout/BlockEndNewline, Layout/MultilineBlockLayout, Layout/MultilineMethodCallBraceLayout, Style/BlockDelimiters, Style/MultilineBlockChain
    context 'when given the valid email' do
      valid_includable.map { |k, v| [
        "include-#{v}-#{k}@valid-characters-in-local.dev"
      ]}.concat(valid_beginable.map { |k, v| [
        "#{v}start-with-#{k}@valid-characters-in-local.dev"
      ]}).concat(valid_endable.map { |k, v| [
        "end-with-#{k}-#{v}@valid-characters-in-local.dev"
      ]}).concat([
        'a+b@plus-in-local.com',
        'a_b@underscore-in-local.com',
        'user@example.com',
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@letters-in-local.dev',
        '01234567890@numbers-in-local.dev',
        'a@single-character-in-local.dev',
        'one-character-third-level@a.example.com',
        'single-character-in-sld@x.dev',
        'local@dash-in-sld.com',
        'numbers-in-sld@s123.com',
        'one-letter-sld@x.dev',
        'uncommon-tld@sld.museum',
        'uncommon-tld@sld.travel',
        'uncommon-tld@sld.mobi',
        'country-code-tld@sld.uk',
        'country-code-tld@sld.rw',
        'local@sld.newTLD',
        'local@sub.domains.com',
        'aaa@bbb.co.jp',
        'nigel.worthington@big.co.uk',
        'f@c.com',
        'f@s.c',
        'someuser@somehost.somedomain',
        'mixed-1234-in-{+^}-local@sld.dev',
        'partially."quoted"@sld.com',
        'areallylongnameaasdfasdfasdfasdf@asdfasdfasdfasdfasdf.ab.cd.ef.gh.co.ca',
        'john.doe@2020.example.com',
        'john.doe@2a.com',
        'john.doe@a2.com',
        'john.doe@2020.a-z.com',
        'john.doe@2020.a2z.com',
        'john.doe@2020.12345a6789.com',
        'jonh.doe@163.com',
        'test@umläut.com', # non-ASCII
        'test@xn--umlut-ira.com' # ASCII-compatibale encoding of non-ASCII
      ]).flatten.each do |email|
        context 'when using defaults' do
          it "'#{email}' should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should be valid" do
            expect(StrictUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should not be invalid using EmailValidator.valid?" do
            expect(described_class).not_to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(true)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should be valid" do
            expect(RfcUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(true)
          end
        end
      end
    end

    context 'when given the valid host-only email' do
      [
        'f@s',
        'user@localhost',
        'someuser@somehost'
      ].each do |email|
        context 'when using defaults' do
          it "'#{email}' should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should be valid" do
            expect(RfcUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(true)
          end
        end
      end
    end

    context 'when given the numeric domain' do
      [
        'only-numbers-in-domain-label@sub.123.custom'
      ].each do |email|
        context 'when using defaults' do
          it "'#{email}' should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should be valid" do
            expect(StrictUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be not invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(true)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should be valid" do
            expect(RfcUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(true)
          end
        end
      end
    end

    context 'when given the valid mailbox-only email' do
      valid_includable.map { |k, v| [
        "user-#{v}-#{k}-name"
      ]}.concat(valid_beginable.map { |k, v| [
        "#{v}-start-with-#{k}-user"
      ]}).concat(valid_endable.map { |k, v| [
        "end-with-#{k}-#{v}"
      ]}).concat([
        'user'
      ]).flatten.each do |email|
        context 'when using defaults' do
          it "'#{email}' should not be valid" do
            expect(DefaultUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(false)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should be valid" do
            expect(RfcUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(true)
          end
        end
      end
    end

    context 'when given the valid IP address email' do
      [
        'bracketed-IP@[127.0.0.1]',
        'bracketed-and-labeled-IPv6@[IPv6:abcd:ef01:1234:5678:9abc:def0:1234:5678]'
      ].each do |email|
        context 'when using defaults' do
          it "'#{email}' should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should be valid" do
            expect(RfcUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(true)
          end
        end
      end
    end

    context 'when given the invalid email' do
      invalid_includable.map { |k, v| [
        "include-#{v}-#{k}@invalid-characters-in-local.dev"
      ]}.concat(domain_invalid_beginable.map { |k, v| [
        "start-with-#{k}@#{v}invalid-characters-in-domain.dev"
      ]}).concat(domain_invalid_endable.map { |k, v| [
        "end-with-#{k}@invalid-characters-in-domain#{v}.dev"
      ]}).concat(domain_invalid_includable.map { |k, v| [
        "include-#{k}@invalid-characters-#{v}-in-domain.dev"
      ]}).concat([
        'test@example.com@example.com',
        'missing-sld@.com',
        'missing-tld@sld.',
        'unbracketed-IPv6@abcd:ef01:1234:5678:9abc:def0:1234:5678',
        'unbracketed-and-labled-IPv6@IPv6:abcd:ef01:1234:5678:9abc:def0:1234:5678',
        'bracketed-and-unlabeled-IPv6@[abcd:ef01:1234:5678:9abc:def0:1234:5678]',
        'unbracketed-IPv4@127.0.0.1',
        'invalid-IPv4@127.0.0.1.26',
        'another-invalid-IPv4@127.0.0.256',
        'IPv4-and-port@127.0.0.1:25',
        'host-beginning-with-dot@.example.com',
        'domain-beginning-with-dash@-example.com',
        'domain-ending-with-dash@example-.com',
        'the-local-part-is-invalid-if-it-is-longer-than-sixty-four-characters@sld.dev',
        "domain-too-long@t#{".#{'o' * 63}" * 5}.long",
        "user@example.com<script>alert('hello')</script>"
      ]).flatten.each do |email|
        context 'when using defaults' do
          it "'#{email}' should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "'#{email}' should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "'#{email}' should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "'#{email}' should match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should not be valid" do
            expect(RfcUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(false)
          end
        end
      end
    end

    context 'when given the invalid email with whitespace in parts' do
      whitespace.map { |k, v| [
        "include-#{v}-#{k}@invalid-characters-in-local.dev"
      ]}.concat([
        'foo @bar.com',
        "foo\t@bar.com",
        "foo\n@bar.com",
        "foo\r@bar.com",
        'test@ example.com',
        'user@example .com',
        "user@example\t.com",
        "user@example\n.com",
        "user@example\r.com",
        'user@exam ple.com',
        "user@exam\tple.com",
        "user@exam\nple.com",
        "user@exam\rple.com",
        'us er@example.com',
        "us\ter@example.com",
        "us\ner@example.com",
        "us\rer@example.com",
        "user@example.com\n<script>alert('hello')</script>",
        "user@example.com\t<script>alert('hello')</script>",
        "user@example.com\r<script>alert('hello')</script>",
        "user@example.com <script>alert('hello')</script>",
        ' leading-whitespace@example.com',
        'trailing-whitespace@example.com ',
        ' leading-and-trailing-whitespace@example.com ',
        ' user-with-leading-whitespace-space@example.com',
        "\tuser-with-leading-whitespace-tab@example.com",
        "
        user-with-leading-whitespace-newline@example.com",
        'domain-with-trailing-whitespace-space@example.com ',
        "domain-with-trailing-whitespace-tab@example.com\t",
        "domain-with-trailing-whitespace-newline@example.com
        "
      ]).flatten.each do |email|
        context 'when using defaults' do
          it "'#{email}' should not be valid" do
            expect(DefaultUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email =~ described_class.regexp)).to be(false)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should not be valid" do
            expect(RfcUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email =~ described_class.regexp(:mode => :rfc))).to be(false)
          end
        end
      end
    end

    context 'when given the invalid email with missing parts' do
      [
        '',
        '@bar.com',
        'test@',
        '@missing-local.dev',
        ' '
      ].each do |email|
        context 'when using defaults' do
          it "'#{email}' should not be valid" do
            expect(DefaultUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp)).to be(false)
          end
        end

        context 'when in `:strict` mode' do
          it "'#{email}' should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "'#{email}' should not be valid" do
            expect(RfcUser.new(:email => email)).not_to be_valid
          end

          it "'#{email}' should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :rfc)
          end

          it "'#{email}' should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :rfc)
          end

          it "'#{email}' should not match the regexp" do
            expect(!!(email.strip =~ described_class.regexp(:mode => :rfc))).to be(false)
          end
        end
      end
    end

    context 'when given the strictly invalid email' do
      strictly_invalid_includable.map { |k, v| [
        "include-#{v}-#{k}@invalid-characters-in-local.dev"
      ]}.concat(strictly_invalid_beginable.map { |k, v| [
        "#{v}start-with-#{k}@invalid-characters-in-local.dev"
      ]}).concat(strictly_invalid_endable.map { |k, v| [
        "end-with-#{k}#{v}@invalid-characters-in-local.dev"
      ]}).concat([
        'user..-with-double-dots@example.com',
        '.user-beginning-with-dot@example.com',
        'user-ending-with-dot.@example.com',
        'fully-numeric-tld@example.123'
      ]).flatten.each do |email|
        context 'when using defaults' do
          it "#{email.strip} in a model should be valid" do
            expect(DefaultUser.new(:email => email)).to be_valid
          end

          it "#{email.strip} should be valid using EmailValidator.valid?" do
            expect(described_class).to be_valid(email)
          end

          it "#{email.strip} should not be invalid using EmailValidator.invalid?" do
            expect(described_class).not_to be_invalid(email)
          end

          it "#{email.strip} should match the regexp" do
            expect(!!(email =~ described_class.regexp)).to be(true)
          end
        end

        context 'when in `:strict` mode' do
          it "#{email.strip} in a model should not be valid" do
            expect(StrictUser.new(:email => email)).not_to be_valid
          end

          it "#{email.strip} should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :strict)
          end

          it "#{email.strip} should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :strict)
          end

          it "#{email.strip} should not match the regexp" do
            expect(!!(email =~ described_class.regexp(:mode => :strict))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it "#{email.strip} in a model should not be valid" do
            expect(RfcUser.new(:email => email)).not_to be_valid
          end

          it "#{email.strip} should not be valid using EmailValidator.valid?" do
            expect(described_class).not_to be_valid(email, :mode => :rfc)
          end

          it "#{email.strip} should be invalid using EmailValidator.invalid?" do
            expect(described_class).to be_invalid(email, :mode => :rfc)
          end

          it "#{email.strip} should not match the regexp" do
            expect(!!(email =~ described_class.regexp(:mode => :rfc))).to be(false)
          end
        end
      end
    end

    context 'when `require_fqdn` is explicitly enabled with a blank domain' do
      let(:opts) { { :require_fqdn => true, :domain => '' } }

      context 'when given a email containing any domain' do
        let(:email) { 'someuser@somehost' }

        context 'when using defaults' do
          it 'is not valid in a model' do
            expect(RequireFqdnWithEmptyDomainUser.new(:email => email)).not_to be_valid
          end

          it 'is not using EmailValidator.valid?' do
            expect(described_class).not_to be_valid(email, opts)
          end

          it 'is invalid using EmailValidator.invalid?' do
            expect(described_class).to be_invalid(email, opts)
          end

          it 'does not match the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(false)
          end
        end

        context 'when in `:strict` mode' do
          it 'is not valid in a model' do
            expect(RequireEmptyDomainStrictUser.new(:email => email)).not_to be_valid
          end

          it 'is not using EmailValidator.valid?' do
            expect(described_class).not_to be_valid(email, opts.merge({ :mode => :strict }))
          end

          it 'is invalid using EmailValidator.invalid?' do
            expect(described_class).to be_invalid(email, opts.merge({ :mode => :strict }))
          end

          it 'does not match the regexp' do
            expect(!!(email =~ described_class.regexp(opts.merge({ :mode => :strict })))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          it 'is not valid in a model' do
            expect(RequireEmptyDomainRfcUser.new(:email => email)).not_to be_valid
          end

          it 'is not using EmailValidator.valid?' do
            expect(described_class).not_to be_valid(email, opts.merge({ :mode => :rfc }))
          end

          it 'is invalid using EmailValidator.invalid?' do
            expect(described_class).to be_invalid(email, opts.merge({ :mode => :rfc }))
          end

          it 'does not match the regexp' do
            expect(!!(email =~ described_class.regexp(opts.merge({ :mode => :rfc })))).to be(false)
          end
        end
      end
    end

    context 'when `require_fqdn` is explicitly disabled' do
      let(:opts) { { :require_fqdn => false } }

      context 'when given a valid hostname-only email' do
        let(:email) { 'someuser@somehost' }

        context 'when using defaults' do
          it 'is valid using EmailValidator.valid?' do
            expect(described_class).to be_valid(email, opts)
          end

          it 'is not invalid using EmailValidator.invalid?' do
            expect(described_class).not_to be_invalid(email, opts)
          end

          it 'matches the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(true)
          end
        end

        # Strict mode enables `require_fqdn` anyway
        context 'when in `:strict` mode' do
          let(:opts) { { :require_fqdn => false, :mode => :strict } }

          it 'is not valid' do
            expect(NonFqdnStrictUser.new(:email => email)).not_to be_valid
          end

          it 'is not valid using EmailValidator.valid?' do
            expect(described_class).not_to be_valid(email, opts)
          end

          it 'is invalid using EmailValidator.invalid?' do
            expect(described_class).to be_invalid(email, opts)
          end

          it 'matches the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(false)
          end
        end

        context 'when in `:rfc` mode' do
          let(:opts) { { :require_fqdn => false, :mode => :rfc } }

          it 'is valid' do
            expect(NonFqdnRfcUser.new(:email => email)).to be_valid
          end

          it 'is valid using EmailValidator.valid?' do
            expect(described_class).to be_valid(email, opts)
          end

          it 'is not invalid using EmailValidator.invalid?' do
            expect(described_class).not_to be_invalid(email, opts)
          end

          it 'matches the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(true)
          end
        end
      end

      context 'when given a valid email using an FQDN' do
        let(:email) { 'someuser@somehost.somedomain' }

        it 'is valid' do
          expect(NonFqdnStrictUser.new(:email => email)).to be_valid
        end

        # rubocop:disable RSpec/PredicateMatcher
        it 'is valid using EmailValidator.valid?' do
          expect(described_class.valid?(email, opts)).to be(true)
        end

        it 'is not invalid using EmailValidator.invalid?' do
          expect(described_class.invalid?(email, opts)).to be(false)
        end
        # rubocop:enable RSpec/PredicateMatcher

        it 'matches the regexp' do
          expect(!!(email =~ described_class.regexp(opts))).to be(true)
        end

        context 'when in `:rfc` mode' do
          let(:opts) { { :require_fqdn => false, :mode => :rfc } }

          # rubocop:disable RSpec/PredicateMatcher
          it 'is valid using EmailValidator.valid?' do
            expect(described_class.valid?(email, opts)).to be(true)
          end

          it 'is not invalid using EmailValidator.invalid?' do
            expect(described_class.invalid?(email, opts)).to be(false)
          end
          # rubocop:enable RSpec/PredicateMatcher

          it 'is valid' do
            expect(NonFqdnRfcUser.new(:email => email)).to be_valid
          end

          it 'matches the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(true)
          end
        end

        context 'when requiring a non-matching domain' do
          let(:domain) { 'example.com' }
          let(:opts) { { :domain => domain } }

          it 'is not valid' do
            expect(DomainStrictUser.new(:email => email)).not_to be_valid
          end

          it 'is not valid using EmailValidator.valid?' do
            expect(described_class).not_to be_valid(email, opts)
          end

          it 'is invalid using EmailValidator.invalid?' do
            expect(described_class).to be_invalid(email, opts)
          end

          it 'does not matches the regexp' do
            expect(!!(email =~ described_class.regexp(opts))).to be(false)
          end

          context 'when in `:rfc` mode' do
            let(:opts) { { :domain => domain, :require_fqdn => false, :mode => :rfc } }

            it 'is not valid using EmailValidator.valid?' do
              expect(described_class).not_to be_valid(email, opts)
            end

            it 'is invalid using EmailValidator.invalid?' do
              expect(described_class).to be_invalid(email, opts)
            end

            it 'is not valid' do
              expect(DomainRfcUser.new(:email => email)).not_to be_valid
            end

            it 'does not match the regexp' do
              expect(!!(email =~ described_class.regexp(opts))).to be(false)
            end
          end
        end
      end
    end
  end
  # rubocop:enable Layout/BlockEndNewline, Layout/MultilineBlockLayout, Layout/MultilineMethodCallBraceLayout, Style/BlockDelimiters, Style/MultilineBlockChain

  describe 'error messages' do
    context 'when the message is not defined' do
      let(:model) { DefaultUser.new :email => 'invalidemail@' }

      before { model.valid? }

      it 'adds the default message' do
        expect(model.errors[:email]).to include 'is invalid'
      end
    end

    context 'when the message is defined' do
      let(:model) { DefaultUserWithMessage.new :email_address => 'invalidemail@' }

      before { model.valid? }

      it 'adds the customized message' do
        expect(model.errors[:email_address]).to include 'is not looking very good!'
      end
    end
  end

  describe 'nil email' do
    it 'is not valid when :allow_nil option is missing' do
      expect(DefaultUser.new(:email => nil)).not_to be_valid
    end

    it 'is valid when :allow_nil options is set to true' do
      expect(AllowNilDefaultUser.new(:email => nil)).to be_valid
    end

    it 'is not valid when :allow_nil option is set to false' do
      expect(DisallowNilDefaultUser.new(:email => nil)).not_to be_valid
    end
  end

  describe 'limited to a domain' do
    context 'when in `:strict` mode' do
      it 'is not valid with mismatched domain' do
        expect(DomainStrictUser.new(:email => 'user@not-matching.io')).not_to be_valid
      end

      it 'is valid with matching domain' do
        expect(DomainStrictUser.new(:email => 'user@example.com')).to be_valid
      end

      it 'does not interpret the dot as any character' do
        expect(DomainStrictUser.new(:email => 'user@example-com')).not_to be_valid
      end
    end

    context 'when in `:rfc` mode' do
      it 'does not interpret the dot as any character' do
        expect(DomainRfcUser.new(:email => 'user@example-com')).not_to be_valid
      end

      it 'is valid with matching domain' do
        expect(DomainRfcUser.new(:email => 'user@example.com')).to be_valid
      end

      it 'is not valid with mismatched domain' do
        expect(DomainRfcUser.new(:email => 'user@not-matching.io')).not_to be_valid
      end
    end
  end

  describe 'default_options' do
    let(:valid_email) { 'valid-email@localhost.localdomain' }
    let(:invalid_email) { 'invalid email@localhost.localdomain' }

    it 'validates valid using `:loose` mode' do
      expect(DefaultUser.new(:email => valid_email)).to be_valid
    end

    it 'invalidates invalid using `:loose` mode' do
      expect(DefaultUser.new(:email => invalid_email)).to be_invalid
    end

    context 'when `email_validator/strict` has been required' do
      before { require 'email_validator/strict' }

      it 'validates valid using `:strict` mode' do
        expect(DefaultUser.new(:email => valid_email)).to be_valid
      end

      it 'invalidates invalid using `:strict` mode' do
        expect(DefaultUser.new(:email => invalid_email)).to be_invalid
      end
    end

    context 'when `email_validator/rfc` has been required' do
      before { require 'email_validator/rfc' }

      it 'validates valid using `:rfc` mode' do
        expect(DefaultUser.new(:email => valid_email)).to be_valid
      end

      it 'invalidates invalid using `:rfc` mode' do
        expect(DefaultUser.new(:email => invalid_email)).to be_invalid
      end
    end
  end

  context 'with regexp' do
    it 'returns a regexp when asked' do
      expect(described_class.regexp).to be_a(Regexp)
    end

    it 'returns a strict regexp when asked' do
      expect(described_class.regexp(:mode => :strict)).to be_a(Regexp)
    end

    it 'returns a RFC regexp when asked' do
      expect(described_class.regexp(:mode => :rfc)).to be_a(Regexp)
    end

    it 'has different regexp for strict and loose' do
      expect(described_class.regexp(:mode => :strict)).not_to eq(described_class.regexp(:mode => :loose))
    end

    it 'has different regexp for RFC and loose' do
      expect(described_class.regexp(:mode => :rfc)).not_to eq(described_class.regexp(:mode => :loose))
    end

    it 'has different regexp for RFC and strict' do
      expect(described_class.regexp(:mode => :rfc)).not_to eq(described_class.regexp(:mode => :strict))
    end
  end

  context 'with invalid `:mode`' do
    it 'raises an error' do
      expect { described_class.regexp(:mode => :invalid) }.to raise_error(EmailValidator::Error)
    end
  end
end
