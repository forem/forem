module LocalRedis
  module Runtime
    def self.active?
      ENV["LOCAL_REDIS_ACTIVE"] == "1" && !ENV.fetch("LOCAL_REDIS_URL", "").strip.empty?
    end
  end
end
