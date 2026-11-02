module DataUpdateScripts
  # Sessions submitted pre-normalized via the API before AgentSession assigned
  # message indices render as "#undefined" in the curator and can't be curated.
  class BackfillAgentSessionMessageIndices
    def run
      AgentSession
        .where("jsonb_typeof(curated_data->'messages') = 'array'")
        .where("NOT (curated_data->'messages'->0 ? 'index')")
        .find_each do |session|
          data = session.curated_data
          data["messages"].each_with_index { |msg, i| msg["index"] ||= i if msg.is_a?(Hash) }
          session.update_column(:curated_data, data)
        end
    end
  end
end
