module PgHero
  module Methods
    module System
      def system_stats_enabled?
        !system_stats_provider.nil?
      end

      def system_stats_provider
        if aws_db_instance_identifier
          :aws
        elsif gcp_database_id
          :gcp
        elsif azure_resource_id
          :azure
        end
      end

      def cpu_usage(**options)
        system_stats(:cpu, **options)
      end

      def connection_stats(**options)
        system_stats(:connections, **options)
      end

      def replication_lag_stats(**options)
        system_stats(:replication_lag, **options)
      end

      def read_iops_stats(**options)
        system_stats(:read_iops, **options)
      end

      def write_iops_stats(**options)
        system_stats(:write_iops, **options)
      end

      def free_space_stats(**options)
        system_stats(:free_space, **options)
      end

      def rds_stats(metric_name, duration: nil, period: nil, offset: nil, series: false)
        if system_stats_enabled?
          aws_options = {region: aws_region}
          if aws_access_key_id
            aws_options[:access_key_id] = aws_access_key_id
            aws_options[:secret_access_key] = aws_secret_access_key
          end

          client = Aws::CloudWatch::Client.new(aws_options)

          duration = (duration || 1.hour).to_i
          period = (period || 1.minute).to_i
          offset = (offset || 0).to_i
          end_time = Time.at(((Time.now - offset).to_f / period).ceil * period)
          start_time = end_time - duration

          resp = client.get_metric_statistics(
            namespace: "AWS/RDS",
            metric_name: metric_name,
            dimensions: [{name: "DBInstanceIdentifier", value: aws_db_instance_identifier}],
            start_time: start_time.iso8601,
            end_time: end_time.iso8601,
            period: period,
            statistics: ["Average"]
          )
          data = {}
          resp[:datapoints].sort_by { |d| d[:timestamp] }.each do |d|
            data[d[:timestamp]] = d[:average]
          end

          add_missing_data(data, start_time, end_time, period) if series

          data
        else
          raise NotEnabled, "System stats not enabled"
        end
      end

      def azure_stats(metric_name, duration: nil, period: nil, offset: nil, series: false)
        # TODO DRY with RDS stats
        duration = (duration || 1.hour).to_i
        period = (period || 1.minute).to_i
        offset = (offset || 0).to_i
        end_time = Time.at(((Time.now - offset).to_f / period).ceil * period)
        start_time = end_time - duration

        interval =
          case period
          when 60
            "PT1M"
          when 300
            "PT5M"
          when 900
            "PT15M"
          when 1800
            "PT30M"
          when 3600
            "PT1H"
          else
            raise Error, "Unsupported period"
          end

        client = Azure::Monitor::Profiles::Latest::Mgmt::Client.new
        # call utc to convert +00:00 to Z
        timespan = "#{start_time.utc.iso8601}/#{end_time.utc.iso8601}"
        results = client.metrics.list(
          azure_resource_id,
          metricnames: metric_name,
          aggregation: "Average",
          timespan: timespan,
          interval: interval
        )

        data = {}
        result = results.value.first
        if result
          result.timeseries.first.data.each do |point|
            data[point.time_stamp.to_time] = point.average
          end
        end

        add_missing_data(data, start_time, end_time, period) if series

        data
      end

      private

      def gcp_stats(metric_name, duration: nil, period: nil, offset: nil, series: false)
        # TODO DRY with RDS stats
        duration = (duration || 1.hour).to_i
        period = (period || 1.minute).to_i
        offset = (offset || 0).to_i
        end_time = Time.at(((Time.now - offset).to_f / period).ceil * period)
        start_time = end_time - duration

        # validate input since we need to interpolate below
        raise Error, "Invalid metric name" unless metric_name =~ /\A[a-z\/_]+\z/i
        raise Error, "Invalid database id" unless gcp_database_id =~ /\A[a-z0-9\-:]+\z/i

        # we handle four situations:
        # 1. google-cloud-monitoring-v3
        # 2. google-cloud-monitoring >= 1
        # 3. google-cloud-monitoring < 1
        # 4. google-apis-monitoring_v3
        begin
          require "google/cloud/monitoring/v3"
        rescue LoadError
          begin
            require "google/cloud/monitoring"
          rescue LoadError
            require "google/apis/monitoring_v3"
          end
        end

        # for situations 1 and 2
        # Google::Cloud::Monitoring.metric_service is documented
        # but doesn't work for situation 1
        if defined?(Google::Cloud::Monitoring::V3::MetricService::Client)
          client = Google::Cloud::Monitoring::V3::MetricService::Client.new

          interval = Google::Cloud::Monitoring::V3::TimeInterval.new
          interval.end_time = Google::Protobuf::Timestamp.new(seconds: end_time.to_i)
          # subtract period to make sure we get first data point
          interval.start_time = Google::Protobuf::Timestamp.new(seconds: (start_time - period).to_i)

          aggregation = Google::Cloud::Monitoring::V3::Aggregation.new
          # may be better to use ALIGN_NEXT_OLDER for space stats to show most recent data point
          # stick with average for now to match AWS
          aggregation.per_series_aligner = Google::Cloud::Monitoring::V3::Aggregation::Aligner::ALIGN_MEAN
          aggregation.alignment_period = period

          results = client.list_time_series({
            name: "projects/#{gcp_database_id.split(":").first}",
            filter: "metric.type = \"cloudsql.googleapis.com/database/#{metric_name}\" AND resource.label.database_id = \"#{gcp_database_id}\"",
            interval: interval,
            view: Google::Cloud::Monitoring::V3::ListTimeSeriesRequest::TimeSeriesView::FULL,
            aggregation: aggregation
          })
        elsif defined?(Google::Cloud::Monitoring)
          require "google/cloud/monitoring"

          client = Google::Cloud::Monitoring::Metric.new

          interval = Google::Monitoring::V3::TimeInterval.new
          interval.end_time = Google::Protobuf::Timestamp.new(seconds: end_time.to_i)
          # subtract period to make sure we get first data point
          interval.start_time = Google::Protobuf::Timestamp.new(seconds: (start_time - period).to_i)

          aggregation = Google::Monitoring::V3::Aggregation.new
          # may be better to use ALIGN_NEXT_OLDER for space stats to show most recent data point
          # stick with average for now to match AWS
          aggregation.per_series_aligner = Google::Monitoring::V3::Aggregation::Aligner::ALIGN_MEAN
          aggregation.alignment_period = period

          results = client.list_time_series(
            "projects/#{gcp_database_id.split(":").first}",
            "metric.type = \"cloudsql.googleapis.com/database/#{metric_name}\" AND resource.label.database_id = \"#{gcp_database_id}\"",
            interval,
            Google::Monitoring::V3::ListTimeSeriesRequest::TimeSeriesView::FULL,
            aggregation: aggregation
          )
        else
          client = Google::Apis::MonitoringV3::MonitoringService.new

          scope = Google::Apis::MonitoringV3::AUTH_MONITORING_READ
          client.authorization = Google::Auth.get_application_default([scope])

          # default logging is very verbose, but use app default
          results = client.list_project_time_series(
            "projects/#{gcp_database_id.split(":").first}",
            filter: "metric.type = \"cloudsql.googleapis.com/database/#{metric_name}\" AND resource.label.database_id = \"#{gcp_database_id}\"",
            interval_start_time: (start_time - period).iso8601,
            interval_end_time: end_time.iso8601,
            view: 0, # full
            aggregation_alignment_period: "#{period}s",
            aggregation_per_series_aligner: 12 # mean
          ).time_series
        end

        data = {}
        result = results.first
        if result
          result.points.each do |point|
            time = point.interval.start_time
            # string with google-apis-monitoring_v3
            time = time.is_a?(String) ? Time.parse(time) : Time.at(time.seconds)
            value = point.value.double_value
            value *= 100 if metric_name == "cpu/utilization"
            data[time] = value
          end
        end

        add_missing_data(data, start_time, end_time, period) if series

        data
      end

      def system_stats(metric_key, **options)
        case system_stats_provider
        when :aws
          metrics = {
            cpu: "CPUUtilization",
            connections: "DatabaseConnections",
            replication_lag: "ReplicaLag",
            read_iops: "ReadIOPS",
            write_iops: "WriteIOPS",
            free_space: "FreeStorageSpace"
          }
          rds_stats(metrics[metric_key], **options)
        when :gcp
          if metric_key == :free_space
            quota = gcp_stats("disk/quota", **options)
            used = gcp_stats("disk/bytes_used", **options)
            free_space(quota, used)
          else
            metrics = {
              cpu: "cpu/utilization",
              connections: "postgresql/num_backends",
              replication_lag: "replication/replica_lag",
              read_iops: "disk/read_ops_count",
              write_iops: "disk/write_ops_count"
            }
            gcp_stats(metrics[metric_key], **options)
          end
        when :azure
          if metric_key == :free_space
            quota = azure_stats("storage_limit", **options)
            used = azure_stats("storage_used", **options)
            free_space(quota, used)
          else
            replication_lag_stat = azure_flexible_server? ? "physical_replication_delay_in_seconds" : "pg_replica_log_delay_in_seconds"
            metrics = {
              cpu: "cpu_percent",
              connections: "active_connections",
              replication_lag: replication_lag_stat,
              read_iops: "read_iops", # flexible server only
              write_iops: "write_iops" # flexible server only
            }
            raise Error, "Metric not supported" unless metrics[metric_key]
            azure_stats(metrics[metric_key], **options)
          end
        else
          raise NotEnabled, "System stats not enabled"
        end
      end

      def azure_flexible_server?
        azure_resource_id.include?("/Microsoft.DBforPostgreSQL/flexibleServers/")
      end

      # only use data points included in both series
      # this also eliminates need to align Time.now
      def free_space(quota, used)
        data = {}
        quota.each do |k, v|
          data[k] = v - used[k] if v && used[k]
        end
        data
      end

      def add_missing_data(data, start_time, end_time, period)
        time = start_time
        while time < end_time
          data[time] ||= nil
          time += period
        end
      end
    end
  end
end
