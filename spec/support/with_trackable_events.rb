module WithTrackableEventsHelper
  # Forces Trackable callbacks to fire inside the block. Useful only in tests
  # since Trackable defaults to skipping in Rails.env.test?.
  def with_trackable_events(&block)
    previous = Thread.current[:trackable_events_enabled]
    Thread.current[:trackable_events_enabled] = true
    yield
  ensure
    Thread.current[:trackable_events_enabled] = previous
  end
end

RSpec.configure do |config|
  config.include WithTrackableEventsHelper
end
