require "securerandom"
require "time"

module Sidekiq
  module JobUtil
    # These functions encapsulate various job utilities.

    TRANSIENT_ATTRIBUTES = %w[]

    def validate(item)
      raise(ArgumentError, "Job must be a Hash with 'class' and 'args' keys: `#{item}`") unless item.is_a?(Hash) && item.key?("class") && item.key?("args")
      raise(ArgumentError, "Job args must be an Array: `#{item}`") unless item["args"].is_a?(Array)
      raise(ArgumentError, "Job class must be either a Class or String representation of the class name: `#{item}`") unless item["class"].is_a?(Class) || item["class"].is_a?(String)
      raise(ArgumentError, "Job 'at' must be a Numeric timestamp: `#{item}`") if item.key?("at") && !item["at"].is_a?(Numeric)
      raise(ArgumentError, "Job tags must be an Array: `#{item}`") if item["tags"] && !item["tags"].is_a?(Array)
    end

    def verify_json(item)
      job_class = item["wrapped"] || item["class"]
      if Sidekiq[:on_complex_arguments] == :raise
        msg = <<~EOM
          Job arguments to #{job_class} must be native JSON types, see https://github.com/mperham/sidekiq/wiki/Best-Practices.
          To disable this error, remove `Sidekiq.strict_args!` from your initializer.
        EOM
        raise(ArgumentError, msg) unless json_safe?(item)
      elsif Sidekiq[:on_complex_arguments] == :warn
        Sidekiq.logger.warn <<~EOM unless json_safe?(item)
          Job arguments to #{job_class} do not serialize to JSON safely. This will raise an error in
          Sidekiq 7.0. See https://github.com/mperham/sidekiq/wiki/Best-Practices or raise an error today
          by calling `Sidekiq.strict_args!` during Sidekiq initialization.
        EOM
      end
    end

    def normalize_item(item)
      validate(item)

      # merge in the default sidekiq_options for the item's class and/or wrapped element
      # this allows ActiveJobs to control sidekiq_options too.
      defaults = normalized_hash(item["class"])
      defaults = defaults.merge(item["wrapped"].get_sidekiq_options) if item["wrapped"].respond_to?(:get_sidekiq_options)
      item = defaults.merge(item)

      raise(ArgumentError, "Job must include a valid queue name") if item["queue"].nil? || item["queue"] == ""

      # remove job attributes which aren't necessary to persist into Redis
      TRANSIENT_ATTRIBUTES.each { |key| item.delete(key) }

      item["jid"] ||= SecureRandom.hex(12)
      item["class"] = item["class"].to_s
      item["queue"] = item["queue"].to_s
      item["created_at"] ||= Time.now.to_f
      item
    end

    def normalized_hash(item_class)
      if item_class.is_a?(Class)
        raise(ArgumentError, "Message must include a Sidekiq::Job class, not class name: #{item_class.ancestors.inspect}") unless item_class.respond_to?(:get_sidekiq_options)
        item_class.get_sidekiq_options
      else
        Sidekiq.default_job_options
      end
    end

    private

    def json_safe?(item)
      JSON.parse(JSON.dump(item["args"])) == item["args"]
    end
  end
end
