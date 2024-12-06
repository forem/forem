require 'bundler/setup'
require 'flipper'

stats = Flipper[:stats]

# Register group
Flipper.register(:enabled_team_member) do |actor, context|
  combos = context.actors_value.map { |flipper_id| flipper_id.split(";", 2) }
  team_names = combos.select { |class_name, id| class_name == "Team" }.map { |class_name, id| id }
  teams = team_names.map { |name| Team.find(name) }
  teams.any? { |team| team.member?(actor) }
end

# Some class that represents actor that will be trying to do something
class User < Struct.new(:id)
  include Flipper::Identifier
end

class Team
  include Flipper::Identifier
  attr_reader :name

  def self.all
    @all ||= {}
  end

  def self.find(name)
    all.fetch(name.to_s)
  end

  def initialize(name, members)
    @name = name.to_s
    @members = members
    self.class.all[@name] = self
  end

  def id
    @name
  end

  def member?(actor)
    @members.map(&:id).include?(actor.id)
  end
end

jnunemaker = User.new("jnunemaker")
jbarnette = User.new("jbarnette")
aroben = User.new("aroben")

core_app = Team.new(:core_app, [jbarnette, jnunemaker])
feature_flags = Team.new(:feature_flags, [aroben, jnunemaker])

stats.enable_actor jbarnette

actors = [jbarnette, jnunemaker, aroben]

actors.each do |actor|
  if stats.enabled?(actor)
    puts "stats are enabled for #{actor.id}"
  else
    puts "stats are NOT enabled for #{actor.id}"
  end
end

puts "enabling team_actor group"
stats.enable_actor core_app
stats.enable_group :enabled_team_member

actors.each do |actor|
  if stats.enabled?(actor)
    puts "stats are enabled for #{actor.id}"
  else
    puts "stats are NOT enabled for #{actor.id}"
  end
end
