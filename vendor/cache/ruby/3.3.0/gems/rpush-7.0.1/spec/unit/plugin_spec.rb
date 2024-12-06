require 'unit_spec_helper'

describe Rpush::Plugin do
  include Rpush::Reflectable

  it 'can only be initialized once' do
    plugin = double(Rpush::Plugin, unload: nil)
    expect(Rpush::Plugin).to receive(:new).once.and_return(plugin)
    Rpush.plugin(:test)
    Rpush.plugin(:test)
  end

  it 'can be referenced' do
    plugin = Rpush.plugin(:test)
    expect(Rpush.plugins[:test]).to eq(plugin)
  end

  it 'can be configured' do
    plugin = Rpush.plugin(:test)
    plugin.configure do |config|
      config.is_configured = true
    end
    expect(Rpush.config.plugin.test.is_configured).to eq(true)
  end

  it 'can hook up reflections' do
    plugin = Rpush.plugin(:test)
    reflected_error = nil
    plugin.reflect do |on|
      on.error { |error| reflected_error = error }
    end
    error = double
    reflect(:error, error)
    expect(reflected_error).to eq(error)
  end
end
