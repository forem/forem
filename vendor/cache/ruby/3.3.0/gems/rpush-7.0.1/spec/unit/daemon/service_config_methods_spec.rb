require 'unit_spec_helper'

describe Rpush::Daemon::ServiceConfigMethods do
  module ServiceConfigMethodsSpec
    extend Rpush::Daemon::ServiceConfigMethods
    class Delivery; end
  end

  it 'returns the delivery class' do
    expect(ServiceConfigMethodsSpec.delivery_class).to eq ServiceConfigMethodsSpec::Delivery
  end

  it 'instantiates loops' do
    loop_class = Class.new
    app = double
    loop_instance = loop_class.new
    expect(loop_class).to receive(:new).with(app).and_return(loop_instance)
    ServiceConfigMethodsSpec.loops loop_class
    expect(ServiceConfigMethodsSpec.loop_instances(app)).to eq [loop_instance]
  end

  it 'returns a new dispatcher' do
    ServiceConfigMethodsSpec.dispatcher :http, an: :option
    app = double
    dispatcher = double
    expect(Rpush::Daemon::Dispatcher::Http).to receive(:new).with(app, ServiceConfigMethodsSpec::Delivery, an: :option).and_return(dispatcher)
    expect(ServiceConfigMethodsSpec.new_dispatcher(app)).to eq dispatcher
  end

  it 'raises a NotImplementedError for an unknown dispatcher type' do
    expect do
      ServiceConfigMethodsSpec.dispatcher :unknown
      ServiceConfigMethodsSpec.dispatcher_class
    end.to raise_error(NotImplementedError)
  end
end
