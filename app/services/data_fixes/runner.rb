module DataFixes
  class Runner
    def self.call(fix_key)
      fix_class = Registry.fetch!(fix_key)
      fix_class.new.call
    end
  end
end
