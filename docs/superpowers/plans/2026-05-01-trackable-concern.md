# Trackable Concern Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `Trackable` model concern with a registry-based adapter pattern, shipping a Customer.io CDP adapter as the first destination. Infrastructure only — no model adopts the concern in this PR.

**Architecture:** Models include `Trackable` and define `trackable_user_ids` (and optionally `trackable_payload`). `after_commit` callbacks build a payload + changes hash on the web thread, then enqueue one `Trackable::DispatchWorker` per active adapter. The worker calls each adapter's `#track` method. Adapters are registered at boot via `Trackable::Registry.register` and selected via the `TRACKABLE_ADAPTERS` ENV var.

**Tech Stack:** Ruby on Rails, ActiveSupport::Concern, Sidekiq (`Sidekiq::Job`), `analytics-ruby` gem (pointed at `cdp.customer.io`), RSpec.

**Spec:** [`docs/superpowers/specs/2026-05-01-trackable-concern-design.md`](../specs/2026-05-01-trackable-concern-design.md)

> **Post-implementation amendments (2026-05-01):**
> - The plan describes a `Registry.active_with_names` helper returning `[name, instance]` pairs. The shipped registry instead exposes `Registry.active_names` (a list of symbols), since the concern only needs names; the worker re-resolves instances. Tasks 7, 9, 10, 13 reference the older name — refer to the actual code in `app/services/trackable/registry.rb` for the final API.
> - The shared example in Task 13 originally located its mutation target via `attribute_names.first`, which can pick up integer foreign keys (e.g. `user_id`). The shipped version filters to string columns specifically. See `spec/support/shared_examples/trackable.rb`.
> - The shipped `Trackable#track` and `Trackable#track!` honor the `skip_trackable_events` toggle (instance flag, class block, test-env default) — the plan's snippet only guarded against touch-only changes.

---

## Task 1: Add the `analytics-ruby` gem

Add the gem the Customer.io CDP adapter will depend on. Doing it first means the `Segment::Analytics` constant is loadable before we write the adapter spec.

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock` (via bundler)

- [ ] **Step 1: Add gem to Gemfile**

Insert this line in `Gemfile` alphabetically among the top-level gems (after the `algoliasearch-rails` line, ~line 19):

```ruby
gem "analytics-ruby", "~> 2.4" # Segment-compatible analytics client; used by Trackers::CustomerioCdp pointed at cdp.customer.io
```

- [ ] **Step 2: Install gem**

Run: `bundle install`
Expected: success; `Gemfile.lock` updated to include `analytics-ruby`.

- [ ] **Step 3: Verify the gem loads**

Run: `bundle exec ruby -e "require 'segment/analytics'; puts Segment::Analytics::VERSION"`
Expected: prints a version string (no `LoadError`).

- [ ] **Step 4: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "Add analytics-ruby gem for Customer.io CDP tracking adapter"
```

---

## Task 2: `Trackers::Base` adapter interface

The base class every adapter inherits from. It defines the contract: `#track` (required, raises) and `#enabled?` (default true).

**Files:**
- Create: `app/services/trackers/base.rb`
- Create: `spec/services/trackers/base_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/services/trackers/base_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackers::Base do
  describe "#track" do
    it "raises NotImplementedError" do
      expect do
        described_class.new.track(event_name: "x", user_ids: [1], properties: {})
      end.to raise_error(NotImplementedError)
    end
  end

  describe "#enabled?" do
    it "returns true by default" do
      expect(described_class.new.enabled?).to be true
    end
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/services/trackers/base_spec.rb`
Expected: FAIL with `uninitialized constant Trackers` or similar.

- [ ] **Step 3: Implement `Trackers::Base`**

Create `app/services/trackers/base.rb`:

```ruby
module Trackers
  # Base class for all Trackable adapters. Subclasses must implement #track.
  # Adapters that need credentials should override #enabled? — when false,
  # Trackable::DispatchWorker skips the adapter entirely.
  class Base
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      raise NotImplementedError, "#{self.class.name} must implement #track"
    end

    def enabled?
      true
    end
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/services/trackers/base_spec.rb`
Expected: PASS (2 examples).

- [ ] **Step 5: Commit**

```bash
git add app/services/trackers/base.rb spec/services/trackers/base_spec.rb
git commit -m "Add Trackers::Base adapter interface for Trackable"
```

---

## Task 3: `Trackers::Null` no-op adapter

The default adapter. Records nothing. Useful as the safe default in environments that haven't configured a real destination, and useful as a control in tests.

**Files:**
- Create: `app/services/trackers/null.rb`
- Create: `spec/services/trackers/null_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/services/trackers/null_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackers::Null do
  subject(:adapter) { described_class.new }

  describe "#track" do
    it "returns nil and does nothing" do
      expect(adapter.track(event_name: "x", user_ids: [1], properties: { a: 1 })).to be_nil
    end

    it "accepts an optional timestamp" do
      expect do
        adapter.track(event_name: "x", user_ids: [1], properties: {}, timestamp: Time.current)
      end.not_to raise_error
    end
  end

  describe "#enabled?" do
    it "is always enabled" do
      expect(adapter.enabled?).to be true
    end
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/services/trackers/null_spec.rb`
Expected: FAIL with `uninitialized constant Trackers::Null`.

- [ ] **Step 3: Implement `Trackers::Null`**

Create `app/services/trackers/null.rb`:

```ruby
module Trackers
  # Default adapter. Records nothing. Used as a safe default and in test/dev.
  class Null < Base
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      nil
    end
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/services/trackers/null_spec.rb`
Expected: PASS (4 examples).

- [ ] **Step 5: Commit**

```bash
git add app/services/trackers/null.rb spec/services/trackers/null_spec.rb
git commit -m "Add Trackers::Null no-op adapter"
```

---

## Task 4: `Trackable::Registry`

The registry holds adapter classes by name and resolves the **active** set from the `TRACKABLE_ADAPTERS` ENV var. It memoizes adapter **instances** per process so `analytics-ruby`'s internal batching thread can accumulate events across many jobs.

**Files:**
- Create: `app/services/trackable/registry.rb`
- Create: `spec/services/trackable/registry_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/services/trackable/registry_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackable::Registry do
  before { described_class.reset! }
  after  { described_class.reset! }

  let(:dummy_adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
    end
  end

  let(:disabled_adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
      def enabled?; false; end
    end
  end

  describe ".register and .lookup" do
    it "stores and retrieves an adapter class by name" do
      described_class.register(:dummy, dummy_adapter_class)
      expect(described_class.lookup(:dummy)).to eq(dummy_adapter_class)
    end

    it "accepts string or symbol names" do
      described_class.register("dummy", dummy_adapter_class)
      expect(described_class.lookup(:dummy)).to eq(dummy_adapter_class)
    end

    it "returns nil for unknown names" do
      expect(described_class.lookup(:unknown)).to be_nil
    end
  end

  describe ".active" do
    before do
      described_class.register(:dummy, dummy_adapter_class)
      described_class.register(:disabled, disabled_adapter_class)
    end

    it "returns instances for adapters listed in TRACKABLE_ADAPTERS" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "filters out adapters whose #enabled? returns false" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy,disabled")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "ignores unknown adapter names" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy,nope")

      expect(described_class.active.map(&:class)).to eq([dummy_adapter_class])
    end

    it "memoizes instances across calls" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")

      expect(described_class.active.first).to be(described_class.active.first)
    end

    it "returns empty array when TRACKABLE_ADAPTERS is unset" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return(nil)

      expect(described_class.active).to eq([])
    end
  end

  describe ".instance_for" do
    before { described_class.register(:dummy, dummy_adapter_class) }

    it "returns the same memoized instance as #active" do
      first = described_class.instance_for(:dummy)
      expect(first).to be_a(dummy_adapter_class)
      expect(described_class.instance_for(:dummy)).to be(first)
    end

    it "returns nil for unknown names" do
      expect(described_class.instance_for(:nope)).to be_nil
    end
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/services/trackable/registry_spec.rb`
Expected: FAIL with `uninitialized constant Trackable::Registry`.

- [ ] **Step 3: Implement `Trackable::Registry`**

Create `app/services/trackable/registry.rb`:

```ruby
module Trackable
  # Process-level registry of tracking adapters. Adapter classes are registered
  # at boot via Trackable::Registry.register(:name, AdapterClass). The active
  # set is parsed from the comma-separated TRACKABLE_ADAPTERS ENV var.
  #
  # Adapter instances are memoized per-process so background gems (like
  # analytics-ruby) can accumulate batches across Sidekiq jobs.
  module Registry
    class << self
      def register(name, adapter_class)
        adapters[name.to_sym] = adapter_class
      end

      def lookup(name)
        adapters[name.to_sym]
      end

      def instance_for(name)
        klass = lookup(name)
        return nil unless klass

        instances[name.to_sym] ||= klass.new
      end

      def active
        configured_adapter_names
          .filter_map { |name| instance_for(name) }
          .select(&:enabled?)
      end

      def reset!
        @adapters = {}
        @instances = {}
      end

      private

      def adapters
        @adapters ||= {}
      end

      def instances
        @instances ||= {}
      end

      def configured_adapter_names
        ApplicationConfig["TRACKABLE_ADAPTERS"].to_s.split(",").map { |n| n.strip.to_sym }.reject { |n| n.empty? }
      end
    end
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/services/trackable/registry_spec.rb`
Expected: PASS (9 examples).

- [ ] **Step 5: Commit**

```bash
git add app/services/trackable/registry.rb spec/services/trackable/registry_spec.rb
git commit -m "Add Trackable::Registry for pluggable tracking adapters"
```

---

## Task 5: `Trackable::DispatchWorker` Sidekiq job

The worker fans events out to active adapters. Each adapter call is wrapped in a `rescue StandardError` so one failing destination doesn't take down others. Re-raises only when **every** adapter failed, so Sidekiq's retry logic only kicks in on full outages.

**Files:**
- Create: `app/workers/trackable/dispatch_worker.rb`
- Create: `spec/workers/trackable/dispatch_worker_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/workers/trackable/dispatch_worker_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackable::DispatchWorker, type: :worker do
  let(:adapter_class) do
    Class.new(Trackers::Base) do
      def track(event_name:, user_ids:, properties:, timestamp: nil); end
    end
  end

  before { Trackable::Registry.reset! }
  after  { Trackable::Registry.reset! }

  describe "#perform" do
    let(:worker) { described_class.new }

    before do
      Trackable::Registry.register(:dummy, adapter_class)
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")
    end

    it "calls #track on the named adapter with the provided arguments" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track)

      worker.perform("dummy", "article_created", [1, 2], { "title" => "t" }, nil)

      expect(adapter).to have_received(:track).with(
        event_name: "article_created",
        user_ids: [1, 2],
        properties: { "title" => "t" },
        timestamp: nil,
      )
    end

    it "parses an ISO timestamp string back into a Time" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track)
      iso = "2026-05-01T12:00:00Z"

      worker.perform("dummy", "x", [1], {}, iso)

      expect(adapter).to have_received(:track).with(
        hash_including(timestamp: Time.iso8601(iso)),
      )
    end

    it "no-ops when the adapter is unknown" do
      expect { worker.perform("nope", "x", [1], {}, nil) }.not_to raise_error
    end

    it "no-ops when the adapter is disabled" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:enabled?).and_return(false)
      allow(adapter).to receive(:track)

      worker.perform("dummy", "x", [1], {}, nil)

      expect(adapter).not_to have_received(:track)
    end

    it "rescues adapter exceptions and logs them" do
      adapter = Trackable::Registry.instance_for(:dummy)
      allow(adapter).to receive(:track).and_raise(StandardError, "boom")
      allow(Rails.logger).to receive(:error)

      expect { worker.perform("dummy", "x", [1], {}, nil) }.to raise_error(StandardError, "boom")
      expect(Rails.logger).to have_received(:error).with(a_string_including("dummy")).at_least(:once)
    end
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/workers/trackable/dispatch_worker_spec.rb`
Expected: FAIL with `uninitialized constant Trackable::DispatchWorker`.

- [ ] **Step 3: Implement the worker**

Create `app/workers/trackable/dispatch_worker.rb`:

```ruby
module Trackable
  # Fans a tracked event out to a single registered adapter.
  # Trackable::Concern enqueues one of these per active adapter on each event.
  class DispatchWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    def perform(adapter_name, event_name, user_ids, properties, timestamp_iso)
      adapter = Trackable::Registry.instance_for(adapter_name)
      return if adapter.nil? || !adapter.enabled?

      timestamp = timestamp_iso ? Time.iso8601(timestamp_iso) : nil

      adapter.track(
        event_name: event_name,
        user_ids: user_ids,
        properties: properties,
        timestamp: timestamp,
      )
    rescue StandardError => e
      Rails.logger.error(
        "[Trackable::DispatchWorker] adapter=#{adapter_name} event=#{event_name} error=#{e.class}: #{e.message}",
      )
      raise
    end
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/workers/trackable/dispatch_worker_spec.rb`
Expected: PASS (5 examples).

- [ ] **Step 5: Commit**

```bash
git add app/workers/trackable/dispatch_worker.rb spec/workers/trackable/dispatch_worker_spec.rb
git commit -m "Add Trackable::DispatchWorker to fan events to adapters"
```

---

## Task 6: `Trackable` concern — skeleton + payload defaults

This task creates the concern with two responsibilities only:

1. Requires the including class to define `trackable_user_ids` (raises `NotImplementedError` otherwise).
2. Provides a `trackable_payload` default implementation (`as_json` minus default-excluded keys).

We do **not** add any callbacks yet — that's the next task. Splitting the work this way keeps each test step focused.

**Files:**
- Create: `app/models/concerns/trackable.rb`
- Create: `spec/models/concerns/trackable_spec.rb`

- [ ] **Step 1: Write failing tests (skeleton + payload)**

Create `spec/models/concerns/trackable_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackable do
  # We define a temporary AR-backed table so we can include the concern
  # without coupling the spec to any production model.
  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :trackable_test_records, force: true do |t|
          t.string  :name
          t.integer :user_id
          t.datetime :engaged_at
          t.timestamps
        end
      end
    end
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.drop_table :trackable_test_records
    end
  end

  let(:trackable_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "trackable_test_records"
      include Trackable

      def self.name
        "TrackableTestRecord"
      end

      def trackable_user_ids
        user_id
      end
    end
  end

  describe "#trackable_user_ids" do
    it "raises NotImplementedError when not defined by the including class" do
      anon_class = Class.new(ApplicationRecord) do
        self.table_name = "trackable_test_records"
        include Trackable
        def self.name; "Anon"; end
      end

      record = anon_class.new
      expect { record.trackable_user_ids }.to raise_error(NotImplementedError)
    end
  end

  describe "#trackable_payload" do
    it "returns as_json minus DEFAULT_EXCLUDED_KEYS" do
      record = trackable_class.new(name: "alpha", user_id: 7)
      payload = record.trackable_payload

      expect(payload).to include("name" => "alpha", "user_id" => 7)
      expect(payload.keys).not_to include("created_at", "updated_at")
    end

    it "is overridable per model" do
      overridden = Class.new(trackable_class) do
        def self.name; "Overridden"; end
        def trackable_payload; { only: name }; end
      end

      expect(overridden.new(name: "n").trackable_payload).to eq(only: "n")
    end
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: FAIL with `uninitialized constant Trackable`.

- [ ] **Step 3: Implement the concern skeleton**

Create `app/models/concerns/trackable.rb`:

```ruby
module Trackable
  extend ActiveSupport::Concern

  DEFAULT_EXCLUDED_KEYS = %w[created_at updated_at].freeze

  def trackable_user_ids
    raise NotImplementedError, "#{self.class.name} must implement #trackable_user_ids"
  end

  def trackable_payload
    as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: PASS (3 examples).

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/trackable.rb spec/models/concerns/trackable_spec.rb
git commit -m "Add Trackable concern skeleton with payload defaults"
```

---

## Task 7: Lifecycle callbacks (create / update / destroy)

Add `after_commit` callbacks that enqueue dispatch jobs for `model_created`, `model_updated`, `model_destroyed`. Destroy needs the user-id snapshot from `before_destroy` because associations may have been chained-destroyed by the time `after_commit` fires.

**Note for this task:** we'll also need to set up the test environment to have events actually fire, since the spec helper from Task 9 (skip-by-default-in-test) doesn't exist yet. For now, events fire unconditionally — we'll add the toggle in Task 9 and update the existing tests then.

**Files:**
- Modify: `app/models/concerns/trackable.rb`
- Modify: `spec/models/concerns/trackable_spec.rb`

- [ ] **Step 1: Add `Registry.active_with_names`**

The concern needs both the adapter **name** (a string, for the worker arg) and the **instance** (to check `enabled?`). Add a paired-return method to the registry.

In `app/services/trackable/registry.rb`, replace the `active` method and add `active_with_names`:

```ruby
      def active
        active_with_names.map { |_name, instance| instance }
      end

      def active_with_names
        configured_adapter_names
          .filter_map { |name| instance = instance_for(name); [name, instance] if instance }
          .select { |_name, instance| instance.enabled? }
      end
```

- [ ] **Step 2: Add registry spec for `active_with_names`**

Append inside the `describe ".active"` block in `spec/services/trackable/registry_spec.rb`:

```ruby
    it ".active_with_names returns [name, instance] pairs" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("TRACKABLE_ADAPTERS").and_return("dummy")

      result = described_class.active_with_names
      expect(result.size).to eq(1)
      expect(result.first[0]).to eq(:dummy)
      expect(result.first[1]).to be_a(dummy_adapter_class)
    end
```

Run: `bundle exec rspec spec/services/trackable/registry_spec.rb`
Expected: PASS.

- [ ] **Step 3: Write failing lifecycle tests**

Append inside the `RSpec.describe Trackable do` block in `spec/models/concerns/trackable_spec.rb` (before the closing `end`):

```ruby
  describe "lifecycle callbacks" do
    before do
      stub_adapter = instance_double(Trackers::Base, enabled?: true)
      allow(stub_adapter).to receive(:track)
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    it "enqueues a model_created event after create" do
      trackable_class.create!(name: "alpha", user_id: 7)

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_created",
        [7],
        hash_including("name" => "alpha", "user_id" => 7),
        kind_of(String),
      )
    end

    it "enqueues a model_updated event after update" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      record.update!(name: "beta")

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_updated",
        [7],
        hash_including("name" => "beta"),
        kind_of(String),
      )
    end

    it "enqueues a model_destroyed event after destroy with the snapshotted user ids" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      record.destroy!

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        "any",
        "trackable_test_record_destroyed",
        [7],
        kind_of(Hash),
        kind_of(String),
      )
    end

    it "does not enqueue when transaction is rolled back" do
      trackable_class.transaction do
        trackable_class.create!(name: "alpha", user_id: 7)
        raise ActiveRecord::Rollback
      end

      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end
  end
```

- [ ] **Step 4: Run tests, verify they fail**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: FAIL — callbacks not wired up; `perform_async` not called.

- [ ] **Step 5: Implement lifecycle callbacks**

Replace the contents of `app/models/concerns/trackable.rb`:

```ruby
module Trackable
  extend ActiveSupport::Concern

  DEFAULT_EXCLUDED_KEYS = %w[created_at updated_at].freeze
  TOUCH_ONLY_KEYS       = %w[updated_at engaged_at].freeze

  included do
    after_commit :enqueue_trackable_event_created,   on: :create
    after_commit :enqueue_trackable_event_updated,   on: :update
    after_commit :enqueue_trackable_event_destroyed, on: :destroy

    before_destroy :snapshot_trackable_user_ids
    after_rollback :clear_trackable_user_id_snapshot, on: :destroy
  end

  def trackable_user_ids
    raise NotImplementedError, "#{self.class.name} must implement #trackable_user_ids"
  end

  def trackable_payload
    as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)
  end

  private

  def enqueue_trackable_event_created
    enqueue_trackable_event("#{model_name.param_key}_created")
  end

  def enqueue_trackable_event_updated
    enqueue_trackable_event("#{model_name.param_key}_updated")
  end

  def enqueue_trackable_event_destroyed
    enqueue_trackable_event(
      "#{model_name.param_key}_destroyed",
      user_ids: @_trackable_destroyed_user_ids || Array.wrap(trackable_user_ids).compact.uniq,
    )
  end

  def enqueue_trackable_event(event_name, user_ids: nil, properties_override: {})
    user_ids = Array.wrap(user_ids || trackable_user_ids).compact.uniq
    return if user_ids.empty?

    properties = trackable_payload.merge(properties_override)
    timestamp  = Time.current.iso8601

    Trackable::Registry.active_with_names.each do |adapter_name, _adapter|
      Trackable::DispatchWorker.perform_async(
        adapter_name.to_s, event_name, user_ids, properties, timestamp,
      )
    end
  end

  def snapshot_trackable_user_ids
    @_trackable_destroyed_user_ids = Array.wrap(trackable_user_ids).compact.uniq
  end

  def clear_trackable_user_id_snapshot
    @_trackable_destroyed_user_ids = nil
  end
end
```

- [ ] **Step 6: Run tests, verify they pass**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb spec/services/trackable/registry_spec.rb`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/models/concerns/trackable.rb app/services/trackable/registry.rb spec/models/concerns/trackable_spec.rb spec/services/trackable/registry_spec.rb
git commit -m "Add Trackable lifecycle callbacks (create, update, destroy)"
```

---

## Task 8: Touch-only suppression on update

A touch-only update (only `updated_at` and/or `engaged_at` changed) should not fire an event. This direct port from `~/core` keeps high-frequency `touch` calls from spamming the destination.

**Files:**
- Modify: `app/models/concerns/trackable.rb`
- Modify: `spec/models/concerns/trackable_spec.rb`

- [ ] **Step 1: Write failing test**

Append inside the `describe "lifecycle callbacks"` block in `spec/models/concerns/trackable_spec.rb`:

```ruby
    it "does not enqueue model_updated when only touch-only keys changed" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      allow(Trackable::DispatchWorker).to receive(:perform_async)

      record.touch  # rubocop:disable Rails/SkipsModelValidations

      expect(Trackable::DispatchWorker).not_to have_received(:perform_async).with(
        anything, "trackable_test_record_updated", anything, anything, anything,
      )
    end

    it "still enqueues model_updated when a non-touch-only key also changed" do
      record = trackable_class.create!(name: "alpha", user_id: 7)
      allow(Trackable::DispatchWorker).to receive(:perform_async)

      record.update!(name: "beta")

      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        anything, "trackable_test_record_updated", anything, anything, anything,
      )
    end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb -e "touch-only"`
Expected: FAIL — `model_updated` fires on touch.

- [ ] **Step 3: Implement touch-only suppression**

Replace `enqueue_trackable_event_updated` in `app/models/concerns/trackable.rb`:

```ruby
  def enqueue_trackable_event_updated
    return if touch_only_change?

    enqueue_trackable_event("#{model_name.param_key}_updated")
  end
```

Add the helper at the bottom of the private section:

```ruby
  def touch_only_change?
    (previous_changes.keys - Trackable::TOUCH_ONLY_KEYS).empty?
  end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/trackable.rb spec/models/concerns/trackable_spec.rb
git commit -m "Suppress Trackable model_updated events on touch-only changes"
```

---

## Task 9: `skip_trackable_events` toggle

Add an instance-level `skip_trackable_events` accessor and a class-level `Class.skip_trackable_events { ... }` block. Default `false` — but in `Rails.env.test?` the default is `true` so the suite isn't accidentally chatty.

Specs that want events flowing in test env opt in via `with_trackable_events` (an RSpec helper we add here too).

**Files:**
- Modify: `app/models/concerns/trackable.rb`
- Modify: `spec/models/concerns/trackable_spec.rb`
- Create: `spec/support/with_trackable_events.rb`

- [ ] **Step 1: Add the test helper**

Create `spec/support/with_trackable_events.rb`:

```ruby
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
```

- [ ] **Step 2: Update existing concern tests to wrap in `with_trackable_events`**

In `spec/models/concerns/trackable_spec.rb`, replace the `before` block of the `describe "lifecycle callbacks"` block with:

```ruby
    before do
      stub_adapter = instance_double(Trackers::Base, enabled?: true)
      allow(stub_adapter).to receive(:track)
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    around do |example|
      with_trackable_events { example.run }
    end
```

- [ ] **Step 3: Add failing tests for the toggle**

Append to `spec/models/concerns/trackable_spec.rb` (a new `describe` block at the top level inside `describe Trackable do`):

```ruby
  describe "skip toggle" do
    before do
      stub_adapter = instance_double(Trackers::Base, enabled?: true)
      allow(stub_adapter).to receive(:track)
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    it "skips events by default in Rails.env.test?" do
      trackable_class.create!(name: "alpha", user_id: 7)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end

    it "fires events inside with_trackable_events" do
      with_trackable_events do
        trackable_class.create!(name: "alpha", user_id: 7)
      end
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
    end

    it "skips events on instances with skip_trackable_events = true" do
      with_trackable_events do
        record = trackable_class.new(name: "alpha", user_id: 7)
        record.skip_trackable_events = true
        record.save!
      end
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end

    it "skips events inside the class-level skip_trackable_events block" do
      with_trackable_events do
        trackable_class.skip_trackable_events do
          trackable_class.create!(name: "alpha", user_id: 7)
        end
      end
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end
  end
```

- [ ] **Step 4: Run tests, verify they fail**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: FAIL — toggle behavior not implemented; existing lifecycle tests now also fail without `with_trackable_events`.

- [ ] **Step 5: Implement the toggle**

Replace the entire `app/models/concerns/trackable.rb` with:

```ruby
module Trackable
  extend ActiveSupport::Concern

  DEFAULT_EXCLUDED_KEYS = %w[created_at updated_at].freeze
  TOUCH_ONLY_KEYS       = %w[updated_at engaged_at].freeze

  included do
    attr_accessor :skip_trackable_events

    after_commit :enqueue_trackable_event_created,   on: :create,  unless: :trackable_events_skipped?
    after_commit :enqueue_trackable_event_updated,   on: :update,  unless: :trackable_events_skipped?
    after_commit :enqueue_trackable_event_destroyed, on: :destroy, unless: :trackable_events_skipped?

    before_destroy :snapshot_trackable_user_ids, unless: :trackable_events_skipped?
    after_rollback :clear_trackable_user_id_snapshot, on: :destroy
  end

  class_methods do
    # Block-scoped, class-level skip. All instances of this class skip events
    # while the block runs. Useful for backfills and migrations.
    def skip_trackable_events
      key = "trackable_skip_class_#{name}"
      previous = Thread.current[key]
      Thread.current[key] = true
      yield
    ensure
      Thread.current[key] = previous
    end

    def trackable_class_skipped?
      Thread.current["trackable_skip_class_#{name}"] == true
    end
  end

  def trackable_user_ids
    raise NotImplementedError, "#{self.class.name} must implement #trackable_user_ids"
  end

  def trackable_payload
    as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)
  end

  private

  def trackable_events_skipped?
    return true if skip_trackable_events
    return true if self.class.trackable_class_skipped?
    return true if Rails.env.test? && !Thread.current[:trackable_events_enabled]

    false
  end

  def enqueue_trackable_event_created
    enqueue_trackable_event("#{model_name.param_key}_created")
  end

  def enqueue_trackable_event_updated
    return if touch_only_change?

    enqueue_trackable_event("#{model_name.param_key}_updated")
  end

  def enqueue_trackable_event_destroyed
    enqueue_trackable_event(
      "#{model_name.param_key}_destroyed",
      user_ids: @_trackable_destroyed_user_ids || Array.wrap(trackable_user_ids).compact.uniq,
    )
  end

  def enqueue_trackable_event(event_name, user_ids: nil, properties_override: {})
    user_ids = Array.wrap(user_ids || trackable_user_ids).compact.uniq
    return if user_ids.empty?

    properties = trackable_payload.merge(properties_override)
    timestamp  = Time.current.iso8601

    Trackable::Registry.active_with_names.each do |adapter_name, _adapter|
      Trackable::DispatchWorker.perform_async(
        adapter_name.to_s, event_name, user_ids, properties, timestamp,
      )
    end
  end

  def touch_only_change?
    (previous_changes.keys - Trackable::TOUCH_ONLY_KEYS).empty?
  end

  def snapshot_trackable_user_ids
    @_trackable_destroyed_user_ids = Array.wrap(trackable_user_ids).compact.uniq
  end

  def clear_trackable_user_id_snapshot
    @_trackable_destroyed_user_ids = nil
  end
end
```

- [ ] **Step 6: Run tests, verify they pass**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/models/concerns/trackable.rb spec/models/concerns/trackable_spec.rb spec/support/with_trackable_events.rb
git commit -m "Add skip_trackable_events toggle (instance, class block, test default)"
```

---

## Task 10: Public `track` and `track!` methods

`track(event_name)` — fires only if there are non-touch-only changes. `track!(event_name)` — force-fires regardless. These are the "ad hoc event" entry points (e.g. a service firing `article_published_to_feed`).

**Files:**
- Modify: `app/models/concerns/trackable.rb`
- Modify: `spec/models/concerns/trackable_spec.rb`

- [ ] **Step 1: Write failing tests**

Append to `spec/models/concerns/trackable_spec.rb` (new top-level `describe`):

```ruby
  describe "#track and #track!" do
    let(:stub_adapter) { instance_double(Trackers::Base, enabled?: true).tap { |a| allow(a).to receive(:track) } }

    before do
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    around { |ex| with_trackable_events { ex.run } }

    describe "#track" do
      it "fires when there are non-touch-only changes" do
        record = trackable_class.create!(name: "alpha", user_id: 7)
        record.assign_attributes(name: "beta")
        record.save!

        result = record.track("custom_event")

        expect(result).to be true
        expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
          "any", "custom_event", [7], hash_including("name" => "beta"), kind_of(String),
        )
      end

      it "returns false and does not fire when only touch-only keys changed" do
        record = trackable_class.create!(name: "alpha", user_id: 7)
        record.touch  # rubocop:disable Rails/SkipsModelValidations
        allow(Trackable::DispatchWorker).to receive(:perform_async)

        result = record.track("custom_event")

        expect(result).to be false
        expect(Trackable::DispatchWorker).not_to have_received(:perform_async).with(
          anything, "custom_event", anything, anything, anything,
        )
      end
    end

    describe "#track!" do
      it "fires regardless of whether there are changes" do
        record = trackable_class.create!(name: "alpha", user_id: 7)
        allow(Trackable::DispatchWorker).to receive(:perform_async)

        record.track!("custom_event")

        expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
          "any", "custom_event", [7], kind_of(Hash), kind_of(String),
        )
      end

      it "merges the optional properties_override into the payload" do
        record = trackable_class.create!(name: "alpha", user_id: 7)
        allow(Trackable::DispatchWorker).to receive(:perform_async)

        record.track!("custom_event", "extra" => "value")

        expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
          anything, anything, anything, hash_including("extra" => "value"), anything,
        )
      end
    end
  end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb -e "#track"`
Expected: FAIL — `#track` not defined.

- [ ] **Step 3: Add public `track` and `track!`**

In `app/models/concerns/trackable.rb`, add these public methods immediately above the `private` keyword:

```ruby
  # Fire `event_name` for this record's trackable users, but only if there are
  # non-touch-only changes since the last save. Returns true if fired, false if
  # suppressed.
  def track(event_name, properties_override = {})
    return false if touch_only_change?

    track!(event_name, properties_override)
    true
  end

  # Fire `event_name` for this record's trackable users regardless of changes.
  def track!(event_name, properties_override = {})
    enqueue_trackable_event(event_name, properties_override: properties_override)
  end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/models/concerns/trackable.rb spec/models/concerns/trackable_spec.rb
git commit -m "Add Trackable#track and Trackable#track! public methods"
```

---

## Task 11: `Trackers::CustomerioCdp` adapter

The adapter wraps `Segment::Analytics` (the `analytics-ruby` gem) pointed at Customer.io's CDP host. `enabled?` returns true only when `CUSTOMERIO_CDP_WRITE_KEY` is set.

**Files:**
- Create: `app/services/trackers/customerio_cdp.rb`
- Create: `spec/services/trackers/customerio_cdp_spec.rb`

- [ ] **Step 1: Write failing tests**

Create `spec/services/trackers/customerio_cdp_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Trackers::CustomerioCdp do
  subject(:adapter) { described_class.new }

  describe "#enabled?" do
    it "is true when CUSTOMERIO_CDP_WRITE_KEY is present" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")

      expect(adapter.enabled?).to be true
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is unset" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return(nil)

      expect(adapter.enabled?).to be false
    end

    it "is false when CUSTOMERIO_CDP_WRITE_KEY is empty" do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("")

      expect(adapter.enabled?).to be false
    end
  end

  describe "#track" do
    let(:client) { instance_double(Segment::Analytics, track: nil) }

    before do
      allow(ApplicationConfig).to receive(:[]).and_call_original
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_WRITE_KEY").and_return("key123")
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return(nil)
      allow(Segment::Analytics).to receive(:new).and_return(client)
    end

    it "constructs the client with the configured write key and default host" do
      adapter.track(event_name: "x", user_ids: [1], properties: {})

      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp.customer.io",
      )
    end

    it "uses CUSTOMERIO_CDP_HOST override when set" do
      allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_CDP_HOST").and_return("cdp-eu.customer.io")

      adapter.track(event_name: "x", user_ids: [1], properties: {})

      expect(Segment::Analytics).to have_received(:new).with(
        write_key: "key123",
        host: "cdp-eu.customer.io",
      )
    end

    it "calls client.track once per user_id" do
      adapter.track(event_name: "article_created", user_ids: [1, 2], properties: { "title" => "t" })

      expect(client).to have_received(:track).with(
        user_id: "1", event: "article_created", properties: { "title" => "t" }, timestamp: nil,
      )
      expect(client).to have_received(:track).with(
        user_id: "2", event: "article_created", properties: { "title" => "t" }, timestamp: nil,
      )
    end

    it "passes timestamp through" do
      ts = Time.iso8601("2026-05-01T12:00:00Z")
      adapter.track(event_name: "x", user_ids: [1], properties: {}, timestamp: ts)

      expect(client).to have_received(:track).with(hash_including(timestamp: ts))
    end

    it "stringifies user ids" do
      adapter.track(event_name: "x", user_ids: [42], properties: {})

      expect(client).to have_received(:track).with(hash_including(user_id: "42"))
    end

    it "memoizes the client across multiple calls on the same instance" do
      adapter.track(event_name: "x", user_ids: [1], properties: {})
      adapter.track(event_name: "y", user_ids: [2], properties: {})

      expect(Segment::Analytics).to have_received(:new).once
    end
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/services/trackers/customerio_cdp_spec.rb`
Expected: FAIL with `uninitialized constant Trackers::CustomerioCdp`.

- [ ] **Step 3: Implement the adapter**

Create `app/services/trackers/customerio_cdp.rb`:

```ruby
module Trackers
  # Customer.io CDP (formerly Data Pipelines) adapter. The Pipelines API is
  # Segment-compatible; we use the analytics-ruby gem pointed at cdp.customer.io.
  #
  # Configure via ENV:
  #   CUSTOMERIO_CDP_WRITE_KEY  required; absence leaves the adapter disabled
  #   CUSTOMERIO_CDP_HOST       optional override; defaults to cdp.customer.io
  class CustomerioCdp < Base
    DEFAULT_HOST = "cdp.customer.io".freeze

    def enabled?
      ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"].present?
    end

    def track(event_name:, user_ids:, properties:, timestamp: nil)
      Array.wrap(user_ids).each do |user_id|
        client.track(
          user_id: user_id.to_s,
          event: event_name,
          properties: properties,
          timestamp: timestamp,
        )
      end
    end

    private

    def client
      @client ||= Segment::Analytics.new(
        write_key: ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"],
        host: ApplicationConfig["CUSTOMERIO_CDP_HOST"].presence || DEFAULT_HOST,
      )
    end
  end
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/services/trackers/customerio_cdp_spec.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/trackers/customerio_cdp.rb spec/services/trackers/customerio_cdp_spec.rb
git commit -m "Add Trackers::CustomerioCdp adapter via analytics-ruby"
```

---

## Task 12: Initializer registering both adapters

Wire `Null` and `CustomerioCdp` into the registry at boot.

**Files:**
- Create: `config/initializers/trackable.rb`
- Create: `spec/initializers/trackable_spec.rb`

- [ ] **Step 1: Write failing test**

Create `spec/initializers/trackable_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "config/initializers/trackable.rb" do
  it "registers Trackers::Null under :null" do
    expect(Trackable::Registry.lookup(:null)).to eq(Trackers::Null)
  end

  it "registers Trackers::CustomerioCdp under :customerio_cdp" do
    expect(Trackable::Registry.lookup(:customerio_cdp)).to eq(Trackers::CustomerioCdp)
  end
end
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `bundle exec rspec spec/initializers/trackable_spec.rb`
Expected: FAIL — registry has no entries.

- [ ] **Step 3: Create the initializer**

Create `config/initializers/trackable.rb`:

```ruby
# Register the built-in tracking adapters. Contributors can register their own
# adapters from a separate initializer; selection is via the comma-separated
# TRACKABLE_ADAPTERS env var.
Rails.application.config.after_initialize do
  Trackable::Registry.register(:null, Trackers::Null)
  Trackable::Registry.register(:customerio_cdp, Trackers::CustomerioCdp)
end
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `bundle exec rspec spec/initializers/trackable_spec.rb`
Expected: PASS.

- [ ] **Step 5: Verify the full Trackable suite still passes**

Run: `bundle exec rspec spec/models/concerns/trackable_spec.rb spec/services/trackable spec/services/trackers spec/workers/trackable spec/initializers/trackable_spec.rb`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add config/initializers/trackable.rb spec/initializers/trackable_spec.rb
git commit -m "Register Null and CustomerioCdp adapters at boot"
```

---

## Task 13: Shared examples for adopting models

A drop-in `it_behaves_like "trackable"` that any future adopting model can include. Verifies `trackable_user_ids` is implemented and returns a non-empty value, and that `model_updated` fires after a real change.

**Files:**
- Create: `spec/support/shared_examples/trackable.rb`
- Create: `spec/support/shared_examples/trackable_meta_spec.rb`

- [ ] **Step 1: Create the shared examples**

Create `spec/support/shared_examples/trackable.rb`:

```ruby
# Shared examples for any model that includes the Trackable concern.
#
# Usage:
#   RSpec.describe MyModel do
#     subject { build(:my_model) }
#     it_behaves_like "trackable"
#   end
shared_examples_for "trackable" do
  it "includes the Trackable concern" do
    expect(described_class.included_modules).to include(Trackable)
  end

  describe "#trackable_user_ids" do
    it "is defined and returns a non-empty value" do
      subject.save! unless subject.persisted?
      ids = Array.wrap(subject.trackable_user_ids).compact

      expect(ids).not_to be_empty
    end
  end

  describe "lifecycle event firing" do
    let(:stub_adapter) do
      instance_double(Trackers::Base, enabled?: true).tap { |a| allow(a).to receive(:track) }
    end

    before do
      allow(Trackable::Registry).to receive(:active_with_names).and_return([[:any, stub_adapter]])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    around { |ex| with_trackable_events { ex.run } }

    it "enqueues a model_updated event after a non-touch-only change" do
      subject.save! unless subject.persisted?
      subject.touch  # baseline; should not enqueue # rubocop:disable Rails/SkipsModelValidations

      # Trigger a real change. The shared example caller is responsible for the
      # subject having at least one writable, non-touch attribute.
      changeable_attr = (subject.class.attribute_names - Trackable::TOUCH_ONLY_KEYS - %w[id created_at]).first
      raise "subject has no changeable attribute for trackable shared example" unless changeable_attr

      subject.update!(changeable_attr => subject[changeable_attr].to_s + "_x")

      param_key = subject.class.model_name.param_key
      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        anything, "#{param_key}_updated", anything, anything, anything,
      )
    end
  end
end
```

- [ ] **Step 2: Add a meta-spec that verifies the shared example works**

Create `spec/support/shared_examples/trackable_meta_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "trackable shared examples" do
  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :trackable_meta_records, force: true do |t|
          t.string :title
          t.integer :user_id
          t.timestamps
        end
      end
    end
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.drop_table :trackable_meta_records
    end
  end

  before do
    stub_const("TrackableMetaRecord", Class.new(ApplicationRecord) do
      self.table_name = "trackable_meta_records"
      include Trackable
      def self.name; "TrackableMetaRecord"; end
      def trackable_user_ids; user_id; end
    end)
  end

  describe TrackableMetaRecord do
    subject { described_class.new(title: "starter", user_id: 1) }

    it_behaves_like "trackable"
  end
end
```

- [ ] **Step 3: Run the meta spec, verify it passes**

Run: `bundle exec rspec spec/support/shared_examples/trackable_meta_spec.rb`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add spec/support/shared_examples/trackable.rb spec/support/shared_examples/trackable_meta_spec.rb
git commit -m "Add shared examples for models adopting Trackable"
```

---

## Task 14: Final integration check

End-to-end check that everything wires up and lints cleanly.

**Files:** none modified.

- [ ] **Step 1: Run the full Trackable-related suite**

Run:
```bash
bundle exec rspec \
  spec/models/concerns/trackable_spec.rb \
  spec/services/trackable \
  spec/services/trackers \
  spec/workers/trackable \
  spec/initializers/trackable_spec.rb \
  spec/support/shared_examples/trackable_meta_spec.rb
```
Expected: PASS.

- [ ] **Step 2: Run RuboCop on all changed files**

Run:
```bash
bundle exec rubocop \
  app/models/concerns/trackable.rb \
  app/services/trackable \
  app/services/trackers \
  app/workers/trackable \
  config/initializers/trackable.rb \
  spec/models/concerns/trackable_spec.rb \
  spec/services/trackable \
  spec/services/trackers \
  spec/workers/trackable \
  spec/initializers/trackable_spec.rb \
  spec/support/shared_examples/trackable.rb \
  spec/support/shared_examples/trackable_meta_spec.rb \
  spec/support/with_trackable_events.rb
```
Expected: no offenses, or only pre-existing project-wide offenses unrelated to these files. Fix any new offenses introduced by this PR.

- [ ] **Step 3: Confirm no model adopts Trackable yet**

Run: `git grep -n "include Trackable" app/models/`
Expected: no matches. Per the spec, this PR ships infrastructure only; per-model adoption is intentionally deferred.

- [ ] **Step 4: Confirm i18n / Fastly / migration scope unchanged**

Run: `git diff main --stat -- config/locales config/fastly db/migrate db/schema.rb`
Expected: empty diff. None of these directories should have changed.

- [ ] **Step 5: Final commit (only if anything was fixed in steps 2)**

If RuboCop fixes were applied:

```bash
git add -A
git commit -m "Fix RuboCop offenses in Trackable concern and adapters"
```

If nothing was fixed, no commit is needed.

---

## Self-review notes

- **Spec coverage:** Every section of the spec maps to a task — adapter base (T2), Null adapter (T3), Registry (T4), worker (T5), concern (T6–T10), Customer.io adapter (T11), initializer (T12), shared examples (T13). Touch-only suppression (T8), skip toggle (T9), `track`/`track!` (T10), error isolation (T5), destroy snapshot (T7) all have explicit failing tests.
- **No model is adopted in this PR.** Verified by Task 14 step 3.
- **Sidekiq pattern:** uses `include Sidekiq::Job` (per AGENTS.md). No `lock: :until_executing` (events aren't deduplicatable by args).
- **No locale changes, no Fastly changes, no migrations** — infrastructure-only PR. Verified by Task 14 step 4.
- **Test isolation:** the concern spec creates its own temp table (`trackable_test_records`); the shared-examples meta spec creates `trackable_meta_records`. Neither pollutes production tables.
- **Type/name consistency:** `active_with_names` returns `[[Symbol, Trackers::Base], ...]` — the worker takes `String` adapter_name and looks up via `Registry.instance_for(name)` which accepts both. Consistent.
- **Test default:** events are skipped in `Rails.env.test?` unless `with_trackable_events` is wrapped around the example. All concern lifecycle tests wrap their examples accordingly.
