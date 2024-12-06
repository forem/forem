require 'logger'

module Excon
  class LoggingInstrumentor

    def self.instrument(name, params = {})
      params = params.dup

      logger = params[:logger] || Logger.new($stderr)

      # reduce duplication/noise of output
      params.delete(:connection)
      params.delete(:stack)

      if params.has_key?(:headers) && params[:headers].has_key?('Authorization')
        params[:headers] = params[:headers].dup
        params[:headers]['Authorization'] = "REDACTED"
      end

      if params.has_key?(:password)
        params[:password] = "REDACTED"
      end

      if name.include?('request')
        info = "request: " + params[:scheme] + "://" + File.join(params[:host], params[:path])

        if params[:query]
          info << "?"

          if params[:query].is_a?(Hash)
            info << params[:query].to_a.map { |key,value| "#{key}=#{value}" }.join('&')
          else
            info << params[:query]
          end
        end
      else
        response_type = name.split('.').last
        if params[:body]
          info = "#{response_type}: " + params[:body]
        end
      end

      logger.info(info) if info

      yield if block_given?
    end
  end
end
