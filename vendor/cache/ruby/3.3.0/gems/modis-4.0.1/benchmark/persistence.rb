# frozen_string_literal: true

$LOAD_PATH.unshift('benchmark')
require 'bench'

require 'redis/connection/fakedis'
# Redis::Connection::Fakedis.start_recording
Redis::Connection::Fakedis.start_replay(:persistence)
Modis.redis_options = { driver: :fakedis }

class User
  include Modis::Model

  attribute :name, :string, default: 'Test'
  attribute :age, :integer
  attribute :percentage, :float
  attribute :created_at, :timestamp
  attribute :flag, :boolean
  attribute :array, :array
  attribute :hash, :hash
  attribute :string_or_hash, %i[string hash]

  index :name
end

def create_user
  User.create!(name: 'Test', age: 30, percentage: 50.0, created_at: Time.now,
               flag: true, array: [1, 2, 3], hash: { k: :v }, string_or_hash: "an string")
end

n = 10_000

Bench.run do |b|
  b.report(:create) do
    n.times do
      create_user
    end
  end

  b.report(:save) do
    n.times do
      user = User.new
      user.name = 'Test'
      user.age = 30
      user.percentage = 50.0
      user.created_at = Time.now
      user.flag = true
      user.array = [1, 2, 3]
      user.hash = { k: :v }
      user.string_or_hash = "an string"
      user.save!
    end
  end

  b.report(:initialize) do
    n.times do
      User.new(name: 'Test', age: 30, percentage: 50.0, created_at: Time.now,
               flag: true, array: [1, 2, 3], hash: { k: :v }, string_or_hash: "an string")
    end
  end

  b.report(:update_without_changes) do
    user = create_user
    n.times do
      user.update!(name: user.name, age: user.age)
    end
  end

  b.report(:update_with_changes) do
    user = create_user
    n.times do |i|
      user.update_attribute(:name, i.to_s)
    end
  end

  b.report(:reload) do
    user = create_user
    n.times do
      user.reload
    end
  end
end

# Redis::Connection::Fakedis.stop_recording(:persistence)
