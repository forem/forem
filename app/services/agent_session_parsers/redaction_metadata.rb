module AgentSessionParsers
  class RedactionMetadata
    def self.merge(metadata_redactions, scrubber_redactions)
      counts = Hash.new(0)

      Array(metadata_redactions).each do |redaction|
        name = redaction["name"] || redaction["pattern_name"]
        count = redaction["count"] || redaction["match_count"]
        name = name.to_s.strip
        count = count.to_i

        counts[name] += count if name.present? && count.positive?
      end

      scrubber_redactions.each do |redaction|
        counts[redaction.pattern_name] += redaction.match_count.to_i
      end

      counts
        .sort_by { |_, count| -count }
        .map { |name, count| { "name" => name, "count" => count } }
    end

    def self.from_messages(messages)
      counts = Hash.new(0)

      Array(messages).each do |message|
        Array(message.dig("metadata", "redactions")).each do |redaction|
          name = redaction["name"] || redaction["pattern_name"]
          count = redaction["count"] || redaction["match_count"]
          name = name.to_s.strip
          count = count.to_i

          counts[name] += count if name.present? && count.positive?
        end
      end

      counts
        .sort_by { |_, count| -count }
        .map { |name, count| { "name" => name, "count" => count } }
    end
  end
end
