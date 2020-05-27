Flipper.configure do |config|
  config.default do
    # pick an adapter, this uses memory, any will do
    adapter = Flipper::Adapters::ActiveRecord.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end

Flipper::UI.configure do |config|
  # Provide guidance on format for user ids
  config.actors.title = "Actor (ex: User:123)"
  config.actors.description = "ex: User:123"
end
