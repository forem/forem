require 'active_support/concern'
require 'active_support/lazy_load_hooks'

require 'counter_culture/version'
require 'counter_culture/extensions'
require 'counter_culture/counter'
require 'counter_culture/reconciler'
require 'counter_culture/skip_updates'

module CounterCulture
  mattr_accessor :batch_size
  self.batch_size = 1000

  def self.config
    yield(self) if block_given?
    self
  end
end

# extend ActiveRecord with our own code here
ActiveSupport.on_load(:active_record) do
  include CounterCulture::Extensions
  include CounterCulture::SkipUpdates
end
