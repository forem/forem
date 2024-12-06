require 'flipper/adapters/sync'
require 'flipper/adapters/operation_logger'
require 'active_support/notifications'

RSpec.describe Flipper::Adapters::Sync do
  let(:local_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:remote_adapter) do
    Flipper::Adapters::OperationLogger.new Flipper::Adapters::Memory.new
  end
  let(:local) { Flipper.new(local_adapter) }
  let(:remote) { Flipper.new(remote_adapter) }
  let(:sync) { Flipper.new(subject) }

  subject do
    described_class.new(local_adapter, remote_adapter, interval: 1)
  end

  it_should_behave_like 'a flipper adapter'

  context 'when local has never been synced' do
    it 'syncs boolean' do
      remote.enable(:search)
      expect(sync[:search].boolean_value).to be(true)
      expect(subject.features.sort).to eq(%w(search))
    end

    it 'syncs actor' do
      actor = Flipper::Actor.new("User;1000")
      remote.enable_actor(:search, actor)
      expect(sync[:search].actors_value).to eq(Set[actor.flipper_id])
      expect(subject.features.sort).to eq(%w(search))
    end

    it 'syncs group' do
      remote.enable_group(:search, :staff)
      expect(sync[:search].groups_value).to eq(Set["staff"])
      expect(subject.features.sort).to eq(%w(search))
    end

    it 'syncs percentage of actors' do
      remote.enable_percentage_of_actors(:search, 25)
      expect(sync[:search].percentage_of_actors_value).to eq(25)
      expect(subject.features.sort).to eq(%w(search))
    end

    it 'syncs percentage of time' do
      remote.enable_percentage_of_time(:search, 15)
      expect(sync[:search].percentage_of_time_value).to eq(15)
      expect(subject.features.sort).to eq(%w(search))
    end
  end

  it 'enables boolean locally when remote feature boolean enabled' do
    remote.disable(:search)
    local.disable(:search)
    remote.enable(:search)
    subject # initialize forces sync
    expect(local[:search].boolean_value).to be(true)
  end

  it 'disables boolean locally when remote feature disabled' do
    remote.enable(:search)
    local.enable(:search)
    remote.disable(:search)
    subject # initialize forces sync
    expect(local[:search].boolean_value).to be(false)
  end

  it 'adds local actor when remote actor is added' do
    actor = Flipper::Actor.new("User;235")
    remote.enable_actor(:search, actor)
    subject # initialize forces sync
    expect(local[:search].actors_value).to eq(Set[actor.flipper_id])
  end

  it 'removes local actor when remote actor is removed' do
    actor = Flipper::Actor.new("User;235")
    remote.enable_actor(:search, actor)
    local.enable_actor(:search, actor)
    remote.disable(:search, actor)
    subject # initialize forces sync
    expect(local[:search].actors_value).to eq(Set.new)
  end

  it 'adds local group when remote group is added' do
    group = Flipper::Types::Group.new(:staff)
    remote.enable_group(:search, group)
    subject # initialize forces sync
    expect(local[:search].groups_value).to eq(Set["staff"])
  end

  it 'removes local group when remote group is removed' do
    group = Flipper::Types::Group.new(:staff)
    remote.enable_group(:search, group)
    local.enable_group(:search, group)
    remote.disable(:search, group)
    subject # initialize forces sync
    expect(local[:search].groups_value).to eq(Set.new)
  end

  it 'updates percentage of actors when remote is updated' do
    remote.enable_percentage_of_actors(:search, 10)
    local.enable_percentage_of_actors(:search, 10)
    remote.enable_percentage_of_actors(:search, 15)
    subject # initialize forces sync
    expect(local[:search].percentage_of_actors_value).to eq(15)
  end

  it 'updates percentage of time when remote is updated' do
    remote.enable_percentage_of_time(:search, 10)
    local.enable_percentage_of_time(:search, 10)
    remote.enable_percentage_of_time(:search, 15)
    subject # initialize forces sync
    expect(local[:search].percentage_of_time_value).to eq(15)
  end

  context 'when local and remote match' do
    it 'does not update boolean enabled' do
      local.enable(:search)
      remote.enable(:search)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:enable)).to be(0)
    end

    it 'does not update boolean disabled' do
      local.disable(:search)
      remote.disable(:search)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:disable)).to be(0)
    end

    it 'does not update actors' do
      actor = Flipper::Actor.new("User;235")
      local.enable_actor(:search, actor)
      remote.enable_actor(:search, actor)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:enable)).to be(0)
      expect(local_adapter.count(:disable)).to be(0)
    end

    it 'does not update groups' do
      group = Flipper::Types::Group.new(:staff)
      local.enable_group(:search, group)
      remote.enable_group(:search, group)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:enable)).to be(0)
      expect(local_adapter.count(:disable)).to be(0)
    end

    it 'does not update percentage of actors' do
      local.enable_percentage_of_actors(:search, 10)
      remote.enable_percentage_of_actors(:search, 10)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:enable)).to be(0)
      expect(local_adapter.count(:disable)).to be(0)
    end

    it 'does not update percentage of time' do
      local.enable_percentage_of_time(:search, 10)
      remote.enable_percentage_of_time(:search, 10)
      local_adapter.reset
      subject # initialize forces sync
      expect(local_adapter.count(:enable)).to be(0)
      expect(local_adapter.count(:disable)).to be(0)
    end
  end

  it 'synchronizes for #features' do
    expect(subject).to receive(:synchronize)
    subject.features
  end

  it 'synchronizes for #get' do
    expect(subject).to receive(:synchronize)
    subject.get sync[:search]
  end

  it 'synchronizes for #get_multi' do
    expect(subject).to receive(:synchronize)
    subject.get_multi [sync[:search]]
  end

  it 'synchronizes for #get_all' do
    expect(subject).to receive(:synchronize)
    subject.get_all
  end

  it 'does not raise sync exceptions' do
    exception = StandardError.new
    expect(remote_adapter).to receive(:get_all).and_raise(exception)
    expect { subject.get_all }.not_to raise_error
  end
end
