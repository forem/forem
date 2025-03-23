class MultiStoreCache < ActiveSupport::Cache::Store
  def initialize(*stores)
    @stores = stores
  end

  def read(name, options = nil)
    @stores.first.read(name, options)
  end

  def write(name, value, options = nil)
    @stores.each { |store| store.write(name, value, options) }
  end

  def delete(name, options = nil)
    @stores.each { |store| store.delete(name, options) }
  end

  def clear(options = nil)
    @stores.each { |store| store.clear(options) }
  end
end
