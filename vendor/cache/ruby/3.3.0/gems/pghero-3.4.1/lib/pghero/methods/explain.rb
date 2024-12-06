module PgHero
  module Methods
    module Explain
      # TODO remove in 4.0
      # note: this method is not affected by the explain option
      def explain(sql)
        sql = squish(sql)
        explanation = nil

        # use transaction for safety
        with_transaction(statement_timeout: (explain_timeout_sec * 1000).round, rollback: true) do
          if (sql.sub(/;\z/, "").include?(";") || sql.upcase.include?("COMMIT")) && !explain_safe?
            raise ActiveRecord::StatementInvalid, "Unsafe statement"
          end
          explanation = execute("EXPLAIN #{sql}").map { |v| v["QUERY PLAN"] }.join("\n")
        end

        explanation
      end

      # TODO rename to explain in 4.0
      # note: this method is not affected by the explain option
      def explain_v2(sql, analyze: nil, verbose: nil, costs: nil, settings: nil, generic_plan: nil, buffers: nil, wal: nil, timing: nil, summary: nil, format: "text")
        options = []
        add_explain_option(options, "ANALYZE", analyze)
        add_explain_option(options, "VERBOSE", verbose)
        add_explain_option(options, "SETTINGS", settings)
        add_explain_option(options, "GENERIC_PLAN", generic_plan)
        add_explain_option(options, "COSTS", costs)
        add_explain_option(options, "BUFFERS", buffers)
        add_explain_option(options, "WAL", wal)
        add_explain_option(options, "TIMING", timing)
        add_explain_option(options, "SUMMARY", summary)
        options << "FORMAT #{explain_format(format)}"

        explain("(#{options.join(", ")}) #{sql}")
      end

      private

      def explain_safe?
        select_all("SELECT 1; SELECT 1")
        false
      rescue ActiveRecord::StatementInvalid
        true
      end

      def add_explain_option(options, name, value)
        unless value.nil?
          options << "#{name}#{value ? "" : " FALSE"}"
        end
      end

      # important! validate format to prevent injection
      def explain_format(format)
        if ["text", "xml", "json", "yaml"].include?(format)
          format.upcase
        else
          raise ArgumentError, "Unknown format"
        end
      end
    end
  end
end
