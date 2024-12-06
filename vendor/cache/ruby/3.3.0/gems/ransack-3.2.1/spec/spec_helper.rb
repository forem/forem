require 'machinist/active_record'
require 'polyamorous/polyamorous'
require 'sham'
require 'faker'
require 'ransack'
require 'action_controller'
require 'ransack/helpers'
require 'pry'
require 'simplecov'
require 'byebug'

SimpleCov.start
I18n.enforce_available_locales = false
Time.zone = 'Eastern Time (US & Canada)'
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'support', '*.yml')]

Dir[File.expand_path('../{helpers,support,blueprints}/*.rb', __FILE__)]
.each { |f| require f }

Faker::Config.random = Random.new(0)
Sham.define do
  name        { Faker::Name.name }
  title       { Faker::Lorem.sentence }
  body        { Faker::Lorem.paragraph }
  salary      { |index| 30000 + (index * 1000) }
  tag_name    { Faker::Lorem.words(number: 3).join(' ') }
  note        { Faker::Lorem.words(number: 7).join(' ') }
  only_admin  { Faker::Lorem.words(number: 3).join(' ') }
  only_search { Faker::Lorem.words(number: 3).join(' ') }
  only_sort   { Faker::Lorem.words(number: 3).join(' ') }
  notable_id  { |id| id }
end

RSpec.configure do |config|
  config.alias_it_should_behave_like_to :it_has_behavior, 'has behavior'

  config.before(:suite) do
    message = "Running Ransack specs with #{
      ActiveRecord::Base.connection.adapter_name
      }, Active Record #{::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION
      } and Ruby #{RUBY_VERSION}"
    line = '=' * message.length
    puts line, message, line
    Schema.create
    SubDB::Schema.create
  end

  config.before(:all)   { Sham.reset(:before_all) }
  config.before(:each)  { Sham.reset(:before_each) }

  config.include RansackHelper
  config.include PolyamorousHelper
end

RSpec::Matchers.define :be_like do |expected|
  match do |actual|
    actual.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip ==
      expected.gsub(/^\s+|\s+$/, '').gsub(/\s+/, ' ').strip
  end
end

RSpec::Matchers.define :have_attribute_method do |expected|
  match do |actual|
    actual.attribute_method?(expected)
  end
end
