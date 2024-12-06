module Blazer
  class Result
    attr_reader :data_source, :columns, :rows, :error, :cached_at, :just_cached, :forecast_error

    def initialize(data_source, columns, rows, error, cached_at, just_cached)
      @data_source = data_source
      @columns = columns
      @rows = rows
      @error = error
      @cached_at = cached_at
      @just_cached = just_cached
    end

    def timed_out?
      error == Blazer::TIMEOUT_MESSAGE
    end

    def cached?
      cached_at.present?
    end

    def boom
      @boom ||= begin
        boom = {}
        columns.each_with_index do |key, i|
          smart_columns_data_source =
            ([data_source] + Array(data_source.settings["inherit_smart_settings"]).map { |ds| Blazer.data_sources[ds] }).find { |ds| ds.smart_columns[key] }

          if smart_columns_data_source
            query = smart_columns_data_source.smart_columns[key]
            res =
              if query.is_a?(Hash)
                query
              else
                values = rows.map { |r| r[i] }.compact.uniq
                result = smart_columns_data_source.run_statement(ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{value}", "(?)"), values]))
                result.rows
              end

            boom[key] = Hash[res.map { |k, v| [k.nil? ? k : k.to_s, v] }]
          end
        end
        boom
      end
    end

    def column_types
      @column_types ||= begin
        columns.each_with_index.map do |k, i|
          v = (rows.find { |r| r[i] } || {})[i]
          if boom[k]
            "string"
          elsif v.is_a?(Numeric)
            "numeric"
          elsif v.is_a?(Time) || v.is_a?(Date)
            "time"
          elsif v.nil?
            nil
          elsif v.is_a?(String) && v.encoding == Encoding::BINARY
            "binary"
          else
            "string"
          end
        end
      end
    end

    def chart_type
      @chart_type ||= begin
        if column_types.compact.size >= 2 && column_types.compact == ["time"] + (column_types.compact.size - 1).times.map { "numeric" }
          "line"
        elsif column_types == ["time", "string", "numeric"]
          "line2"
        elsif column_types == ["string", "numeric"] && @columns.last == "pie"
          "pie"
        elsif column_types.compact.size >= 2 && column_types == ["string"] + (column_types.compact.size - 1).times.map { "numeric" }
          "bar"
        elsif column_types == ["string", "string", "numeric"]
          "bar2"
        elsif column_types == ["numeric", "numeric"]
          "scatter"
        end
      end
    end

    def forecastable?
      @forecastable ||= Blazer.forecasting && column_types == ["time", "numeric"] && @rows.size >= 10
    end

    # TODO cache it?
    # don't want to put result data (even hashed version)
    # into cache without developer opt-in
    def forecast
      count = (@rows.size * 0.25).round.clamp(30, 365)

      case Blazer.forecasting
      when "prophet"
        require "prophet"
        forecast = Prophet.forecast(@rows.to_h, count: count)
      else
        require "trend"
        forecast = Trend.forecast(@rows.to_h, count: count)
      end

      # round integers
      if @rows[0][1].is_a?(Integer)
        forecast = forecast.map { |k, v| [k, v.round] }.to_h
      end

      @rows.each do |row|
        row[2] = nil
      end
      @rows.unshift(*forecast.map { |k, v| [k, nil, v] })
      @columns << "forecast"

      # reset cache
      @column_types = nil
      @chart_type = nil

      forecast
    rescue => e
      @forecast_error = String.new("Error generating forecast")
      @forecast_error << ": #{e.message.sub("Invalid parameter: ", "")}"
      nil
    end

    def detect_anomaly
      anomaly = nil
      message = nil

      if rows.empty?
        message = "No data"
      else
        if chart_type == "line" || chart_type == "line2"
          series = []

          if chart_type == "line"
            columns[1..-1].each_with_index.each do |k, i|
              series << {name: k, data: rows.map{ |r| [r[0], r[i + 1]] }}
            end
          else
            rows.group_by { |r| v = r[1]; (boom[columns[1]] || {})[v.to_s] || v }.each_with_index.map do |(name, v), i|
              series << {name: name, data: v.map { |v2| [v2[0], v2[2]] }}
            end
          end

          current_series = nil
          begin
            anomalies = []
            series.each do |s|
              current_series = s[:name]
              anomalies << s[:name] if anomaly?(s[:data])
            end
            anomaly = anomalies.any?
            if anomaly
              if anomalies.size == 1
                message = "Anomaly detected in #{anomalies.first}"
              else
                message = "Anomalies detected in #{anomalies.to_sentence}"
              end
            else
              message = "No anomalies detected"
            end
          rescue => e
            message = "#{current_series}: #{e.message}"
            raise e if Rails.env.development?
          end
        else
          message = "Bad format"
        end
      end

      [anomaly, message]
    end

    def anomaly?(series)
      series = series.reject { |v| v[0].nil? }.sort_by { |v| v[0] }

      case Blazer.anomaly_checks
      when "prophet"
        df = Rover::DataFrame.new(series[0..-2].map { |v| {"ds" => v[0], "y" => v[1]} })
        m = Prophet.new(interval_width: 0.99)
        m.logger.level = ::Logger::FATAL # no logging
        m.fit(df)
        future = Rover::DataFrame.new(series[-1..-1].map { |v| {"ds" => v[0]} })
        forecast = m.predict(future).to_a[0]
        lower = forecast["yhat_lower"]
        upper = forecast["yhat_upper"]
        value = series.last[1]
        value < lower || value > upper
      when "trend"
        anomalies = Trend.anomalies(Hash[series])
        anomalies.include?(series.last[0])
      when "anomaly_detection"
        period = 7 # TODO determine period
        anomalies = AnomalyDetection.detect(Hash[series], period: period)
        anomalies.include?(series.last[0])
      else
        csv_str =
          CSV.generate do |csv|
            csv << ["timestamp", "count"]
            series.each do |row|
              csv << row
            end
          end

        r_script = %x[which Rscript].chomp
        type = series.any? && series.last.first.to_time - series.first.first.to_time >= 2.weeks ? "ts" : "vec"
        args = [type, csv_str]
        raise "R not found" if r_script.empty?
        command = "#{r_script} --vanilla #{File.expand_path("../detect_anomalies.R", __FILE__)} #{args.map { |a| Shellwords.escape(a) }.join(" ")}"
        output = %x[#{command}]
        if output.empty?
          raise "Unknown R error"
        end

        rows = CSV.parse(output, headers: true)
        error = rows.first && rows.first["x"]
        raise error if error

        timestamps = []
        if type == "ts"
          rows.each do |row|
            timestamps << Time.parse(row["timestamp"])
          end
          timestamps.include?(series.last[0].to_time)
        else
          rows.each do |row|
            timestamps << row["index"].to_i
          end
          timestamps.include?(series.length)
        end
      end
    end
  end
end
