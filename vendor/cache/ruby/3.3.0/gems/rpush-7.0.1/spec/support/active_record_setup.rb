require 'active_record'

jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

SPEC_ADAPTER = ENV['ADAPTER'] || 'postgresql'
SPEC_ADAPTER = 'jdbc' + SPEC_ADAPTER if jruby

require 'yaml'
db_config_path = File.expand_path("config/database.yml", File.dirname(__FILE__))
db_config = YAML.load(ERB.new(File.read(db_config_path)).result)

if db_config[SPEC_ADAPTER].nil?
  puts "No such adapter '#{SPEC_ADAPTER}'. Valid adapters are #{db_config.keys.join(', ')}."
  exit 1
end

if ENV['CI']
  db_config[SPEC_ADAPTER]['username'] = 'postgres'
else
  require 'etc'
  username = SPEC_ADAPTER =~ /mysql/ ? 'root' : Etc.getlogin
  db_config[SPEC_ADAPTER]['username'] = username
end

puts "Using #{SPEC_ADAPTER} adapter."

ActiveRecord::Base.configurations = { "test" => db_config[SPEC_ADAPTER] }
ActiveRecord::Base.establish_connection(db_config[SPEC_ADAPTER])

require 'generators/templates/add_rpush'
require 'generators/templates/rpush_2_0_0_updates'
require 'generators/templates/rpush_2_1_0_updates'
require 'generators/templates/rpush_2_6_0_updates'
require 'generators/templates/rpush_2_7_0_updates'
require 'generators/templates/rpush_3_0_0_updates'
require 'generators/templates/rpush_3_0_1_updates'
require 'generators/templates/rpush_3_1_0_add_pushy'
require 'generators/templates/rpush_3_1_1_updates'
require 'generators/templates/rpush_3_2_0_add_apns_p8'
require 'generators/templates/rpush_3_2_4_updates'
require 'generators/templates/rpush_3_3_0_updates'
require 'generators/templates/rpush_3_3_1_updates'
require 'generators/templates/rpush_4_1_0_updates'
require 'generators/templates/rpush_4_1_1_updates'
require 'generators/templates/rpush_4_2_0_updates'

migrations = [
  AddRpush,
  Rpush200Updates,
  Rpush210Updates,
  Rpush260Updates,
  Rpush270Updates,
  Rpush300Updates,
  Rpush301Updates,
  Rpush310AddPushy,
  Rpush311Updates,
  Rpush320AddApnsP8,
  Rpush324Updates,
  Rpush330Updates,
  Rpush331Updates,
  Rpush410Updates,
  Rpush411Updates,
  Rpush420Updates
]

unless ENV['CI']
  migrations.reverse_each do |m|
    begin
      m.down
    rescue ActiveRecord::StatementInvalid => e
      p e
    end
  end
end

migrations.each(&:up)

Rpush::Client::ActiveRecord::Notification.reset_column_information
Rpush::Client::ActiveRecord::App.reset_column_information
Rpush::Client::ActiveRecord::Apns::Feedback.reset_column_information
