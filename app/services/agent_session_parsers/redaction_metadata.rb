module AgentSessionParsers
  class RedactionMetadata
    def self.for_scrub_result(result)
      metadata = result.scrubbed_data.fetch("metadata", {}) || {}
      supplied_redactions = metadata["redactions"].presence
      report = if supplied_redactions
                 merge(supplied_redactions, result.redactions)
               else
                 report_from_messages(result.scrubbed_data["messages"], result.redactions)
               end

      metadata.merge("redactions" => report)
    end

    def self.merge(metadata_redactions, scrubber_redactions)
      counts = Hash.new(0)
      add_metadata_redactions(counts, metadata_redactions)
      add_scrubber_redactions(counts, scrubber_redactions)
      format_counts(counts)
    end

    def self.from_messages(messages)
      counts = ForemNative.aggregate_transcript_redactions(messages) || legacy_message_counts(messages)
      format_counts(counts)
    end

    def self.report_from_messages(messages, scrubber_redactions)
      counts = ForemNative.aggregate_transcript_redactions(messages)
      return merge(format_counts(legacy_message_counts(messages)), scrubber_redactions) unless counts

      # The first sort sets the order of client entries before server counts are added.
      counts = sort_counts(counts).to_h unless counts.empty?
      counts.default = 0
      add_scrubber_redactions(counts, scrubber_redactions)
      format_counts(counts)
    end
    private_class_method :report_from_messages

    def self.legacy_message_counts(messages)
      counts = Hash.new(0)

      Array(messages).each do |message|
        redactions = message.dig("metadata", "redactions")
        add_metadata_redactions(counts, redactions) unless redactions.nil?
      end

      counts
    end
    private_class_method :legacy_message_counts

    def self.add_metadata_redactions(counts, redactions)
      Array(redactions).each do |redaction|
        name = redaction["name"] || redaction["pattern_name"]
        count = redaction["count"] || redaction["match_count"]
        name = name.to_s.strip
        count = count.to_i

        counts[name] += count if name.present? && count.positive?
      end
    end
    private_class_method :add_metadata_redactions

    def self.add_scrubber_redactions(counts, redactions)
      redactions.each { |redaction| counts[redaction.pattern_name] += redaction.match_count.to_i }
    end
    private_class_method :add_scrubber_redactions

    def self.sort_counts(counts)
      counts.sort_by { |_, count| -count }
    end
    private_class_method :sort_counts

    def self.format_counts(counts)
      return [] if counts.empty?

      sort_counts(counts).map { |name, count| { "name" => name, "count" => count } }
    end
    private_class_method :format_counts
  end
end
