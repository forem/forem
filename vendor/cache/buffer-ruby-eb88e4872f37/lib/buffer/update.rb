module Buffer
  class Client
    module Update
      def update_by_id(id, options = {})
        check_id(id)
        response = get("/updates/#{id}.json")
        Buffer::Update.new(response)
      end

      def updates_by_profile_id(id, options = {})
        status = options.fetch(:status) do
          raise Buffer::Error::MissingStatus, "Include :pending or :sent in args"
        end
        options.delete(:status)
        response = get("/profiles/#{id}/updates/#{status.to_s}.json", options)
        updates = response['updates'].map { |r| Buffer::Update.new(r) }
        Buffer::Updates.new (
              { total: response['total'],
                updates: updates }
        )
      end

      def interactions_by_update_id(id, options = {})
        check_id(id)
        response = get("/updates/#{id}/interactions.json", options)
        interactions = response['interactions'].map do |r|
          Buffer::Interaction.new(r)
        end
        Buffer::Interactions.new(
          { total: response['total'], interactions: interactions }
        )
      end

      def reorder_updates(profile_id, options = {})
        options.fetch(:order) { raise ArgumentError }
        post("/profiles/#{profile_id}/updates/reorder.json", body: options)
      end

      def shuffle_updates(profile_id, options = {})
        post("/profiles/#{profile_id}/updates/shuffle.json",
                        body: options)
      end

      def create_update(options = {})
        options[:body].fetch(:text) do
          raise ArgumentError, "Must include text for update"
        end
        options[:body].fetch(:profile_ids) do
          raise ArgumentError, "Must include array of profile_ids"
        end
        post("/updates/create.json", options)
      end

      def modify_update_text(update_id, options = {})
        options[:body].fetch(:text) do
          raise ArgumentError, "Must include updated text"
        end
        post("/updates/#{update_id}/update.json", options)
      end

      def share_update(update_id)
        post("/updates/#{update_id}/share.json")
      end

      def destroy_update(update_id)
        post("/updates/#{update_id}/destroy.json")
      end

      def check_id(id)
        raise Buffer::Error::InvalidIdLength unless id.length == 24
        raise Buffer::Error::InvalidIdContent unless id[/^[a-f0-9]+$/i]
      end
    end
  end
end
