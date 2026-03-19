module DataFixes
  class Registry
    FIXES = {
      FixTagCounts::KEY => FixTagCounts,
    }.freeze

    CHECKS = {
      VerifyTagCounts::KEY => VerifyTagCounts,
    }.freeze

    def self.fetch!(key)
      FIXES.fetch(key) { raise ArgumentError, "Unknown data fix: #{key}" }
    end

    def self.fetch_check!(key)
      CHECKS.fetch(key) { raise ArgumentError, "Unknown data check: #{key}" }
    end

    def self.available_keys
      FIXES.keys
    end
  end
end
