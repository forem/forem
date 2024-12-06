module CounterCulture
  module SkipUpdates
    private

    # called by after_create callback
    def _update_counts_after_create
      unless Array(Thread.current[:skip_counter_culture_updates]).include?(self.class)
        super
      end
    end

    # called by after_destroy callback
    def _update_counts_after_destroy
      unless Array(Thread.current[:skip_counter_culture_updates]).include?(self.class)
        super
      end
    end

    # called by after_update callback
    def _update_counts_after_update
      unless Array(Thread.current[:skip_counter_culture_updates]).include?(self.class)
        super
      end
    end
  end
end
