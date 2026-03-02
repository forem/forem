module DataFixes
  class Registry
    FIXES = {
      FixTagCounts::KEY => FixTagCounts,
    }.freeze

    def self.fetch!(key)
      FIXES.fetch(key) { raise ArgumentError, "Unknown data fix: #{key}" }
    end

    def self.available_keys
      FIXES.keys
    end
  end
end
