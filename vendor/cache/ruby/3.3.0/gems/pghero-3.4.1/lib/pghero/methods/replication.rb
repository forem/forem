module PgHero
  module Methods
    module Replication
      def replica?
        unless defined?(@replica)
          @replica = select_one("SELECT pg_is_in_recovery()")
        end
        @replica
      end

      # https://www.postgresql.org/message-id/CADKbJJWz9M0swPT3oqe8f9+tfD4-F54uE6Xtkh4nERpVsQnjnw@mail.gmail.com
      def replication_lag
        with_feature_support(:replication_lag) do
          lag_condition =
            if server_version_num >= 100000
              "pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()"
            else
              "pg_last_xlog_receive_location() = pg_last_xlog_replay_location()"
            end

          select_one <<~SQL
            SELECT
              CASE
                WHEN NOT pg_is_in_recovery() OR #{lag_condition} THEN 0
                ELSE EXTRACT (EPOCH FROM NOW() - pg_last_xact_replay_timestamp())
              END
            AS replication_lag
          SQL
        end
      end

      def replication_slots
        if server_version_num >= 90400
          with_feature_support(:replication_slots, []) do
            select_all <<~SQL
              SELECT
                slot_name,
                database,
                active
              FROM pg_replication_slots
            SQL
          end
        else
          []
        end
      end

      def replicating?
        with_feature_support(:replicating?, false) do
          select_all("SELECT state FROM pg_stat_replication").any?
        end
      end

      private

      def feature_support
        @feature_support ||= {}
      end

      def with_feature_support(cache_key, default = nil)
        # cache feature support to minimize errors in logs
        return default if feature_support[cache_key] == false

        begin
          yield
        rescue ActiveRecord::StatementInvalid => e
          raise unless e.message.start_with?("PG::FeatureNotSupported:")
          feature_support[cache_key] = false
          default
        end
      end
    end
  end
end
