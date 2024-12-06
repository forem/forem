module VCR
  # @private
  class LibraryHooks
    attr_accessor :exclusive_hook

    def disabled?(hook)
      ![nil, hook].include?(exclusive_hook)
    end

    def exclusively_enabled(hook)
      self.exclusive_hook = hook
      yield
    ensure
      self.exclusive_hook = nil
    end
  end
end

