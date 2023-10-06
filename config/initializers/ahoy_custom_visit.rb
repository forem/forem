require "ahoy"

module Ahoy
  class Store < Ahoy::DatabaseStore
    def track_visit(data)
      if data[:user_id].present?
        # Check if there's a user associated with the visit
        context = UserVisitContext.find_or_initialize_by(
          geolocation: request.headers["X-Client-Geo"],
          user_agent: request.user_agent,
          accept_language: request.headers["HTTP_ACCEPT_LANGUAGE"],
          user_id: data[:user_id],
        )

        # Increase the visit count for this context
        context.increment(:visit_count)

        # Update the last visit timestamp
        context.last_visit_at = data[:started_at]

        # Save context with all changes
        context.save!

        # Associate this visit with the found/created context
        data[:user_visit_context_id] = context.id
      end

      super(data)
    end
  end
end
