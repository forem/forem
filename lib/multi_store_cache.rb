class MultiStoreCache < ActiveSupport::Cache::Store
  DEFAULT_MEMORY_TTL = 10.minutes

  def initialize(*stores)
    @stores = stores.compact
  end

  # Read-through: try tiers in order; if hit on a lower tier, backfill higher tiers.
  def read(name, options = nil)
    options ||= {}
    value = nil

    @stores.each_with_index do |store, index|
      value = store.read(name, options)
      next if value.nil?

      # Backfill all higher-priority stores we already skipped
      # Apply a short TTL for memory-like stores to avoid staleness
      backfill_expires_in = options[:expires_in]
      backfill_expires_in ||= DEFAULT_MEMORY_TTL if memory_store?(store)

      (index - 1).downto(0) do |j|
        backfill_opts = options.dup
        backfill_opts[:expires_in] ||= backfill_expires_in if backfill_expires_in
        @stores[j].write(name, value, backfill_opts)
      end

      break
    end

    value
  end

  # Write-through: write to all stores.
  def write(name, value, options = nil)
    options ||= {}
    @stores.each do |store|
      store.write(name, value, write_options_for(store, options))
    end
  end

  def delete(name, options = nil)
    @stores.each { |store| store.delete(name, options) }
  end

  def clear(options = nil)
    @stores.each { |store| store.clear(options) }
  end

  private

  def memory_store?(store)
    store.is_a?(ActiveSupport::Cache::MemoryStore)
  end

  def write_options_for(store, options)
    return options unless memory_store?(store)

    # Ensure the in-memory tier has a bounded TTL unless a shorter one was provided
    opts = options.dup
    opts[:expires_in] = [opts[:expires_in] || DEFAULT_MEMORY_TTL, DEFAULT_MEMORY_TTL].min
    opts
  end
end
