require 'bundler/setup'
require 'flipper'

stats = Flipper[:stats]

# Register group
Flipper.register(:team_actor) do |actor|
  actor.is_a?(TeamActor) && actor.allowed?
end

# Some class that represents actor that will be trying to do something
class User < Struct.new(:id)
  include Flipper::Identifier
end

class Team
  attr_reader :name

  def initialize(name, members)
    @name = name
    @members = members
  end

  def id
    @name
  end

  def member?(actor)
    @members.include?(actor)
  end
end

class TeamActor
  def initialize(team, actor)
    @team = team
    @actor = actor
  end

  def allowed?
    @team.member?(@actor)
  end

  def flipper_id
    "TeamActor:#{@team.id}:#{@actor.id}"
  end
end

jnunemaker = User.new(1)
jbarnette = User.new(2)
aroben = User.new(3)

core_app = Team.new(:core_app, [jbarnette, jnunemaker])
feature_flags = Team.new(:feature_flags, [aroben, jnunemaker])

core_nunes = TeamActor.new(core_app, jnunemaker)
core_roben = TeamActor.new(core_app, aroben)

if stats.enabled?(core_nunes)
  puts "stats are enabled for jnunemaker"
else
  puts "stats are NOT enabled for jnunemaker"
end

if stats.enabled?(core_roben)
  puts "stats are enabled for aroben"
else
  puts "stats are NOT enabled for aroben"
end

puts "enabling team_actor group"
stats.enable_group :team_actor

if stats.enabled?(core_nunes)
  puts "stats are enabled for jnunemaker"
else
  puts "stats are NOT enabled for jnunemaker"
end

if stats.enabled?(core_roben)
  puts "stats are enabled for aroben"
else
  puts "stats are NOT enabled for aroben"
end
