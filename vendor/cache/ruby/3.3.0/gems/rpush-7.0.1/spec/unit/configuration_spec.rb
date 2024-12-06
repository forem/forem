require 'unit_spec_helper'

describe Rpush do
  let(:config) { Rpush.config }

  before do
    allow(Rpush).to receive_messages(require: nil)
    allow(Rpush).to receive_messages(config: config)
  end

  it 'yields a configure block' do
    expect { |b| Rpush.configure(&b) }.to yield_with_args(config)
  end
end

describe Rpush::Configuration do
  let(:config) do
    Rpush::Deprecation.muted do
      Rpush::Configuration.new
    end
  end

  it 'can be updated' do
    Rpush::Deprecation.muted do
      new_config = Rpush::Configuration.new
      new_config.batch_size = 200
      expect { config.update(new_config) }.to change(config, :batch_size).to(200)
    end
  end

  it 'sets the pid_file relative if not absolute' do
    config.pid_file = 'tmp/rpush.pid'
    expect(config.pid_file).to eq '/tmp/rails_root/tmp/rpush.pid'
  end

  it 'does not alter an absolute pid_file path' do
    config.pid_file = '/tmp/rpush.pid'
    expect(config.pid_file).to eq '/tmp/rpush.pid'
  end

  it 'delegate redis_options to Modis' do
    Rpush.config.client = :redis
    Rpush.config.redis_options = { hi: :mom }
    expect(Modis.redis_options).to eq(hi: :mom)
  end
end
