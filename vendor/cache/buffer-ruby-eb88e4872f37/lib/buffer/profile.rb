module Buffer
  class Client
    module Profile
      def profiles
        response = get("/profiles.json")
        response.map { |profile| Buffer::Profile.new(profile) }
      end

      def profile_by_id(id)
        response = get("/profiles/#{id}.json")
        Buffer::Profile.new(response)
      end

      def schedules_by_profile_id(id)
        response = get("/profiles/#{id}/schedules.json")
        response.map { |a_response| Buffer::Schedule.new(a_response) }
      end

      def set_schedules(id, options)
        schedules = Buffer::Encode.encode(
                        options.fetch(:schedules) { raise ArgumentError })
        post("/profiles/#{id}/schedules/update.json",
                        body: { schedules: schedules })
      end
    end
  end
end
