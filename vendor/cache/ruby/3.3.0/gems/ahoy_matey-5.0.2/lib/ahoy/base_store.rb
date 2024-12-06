module Ahoy
  class BaseStore
    attr_writer :user

    def initialize(options)
      @user = options[:user]
      @options = options
    end

    def track_visit(data)
    end

    def track_event(data)
    end

    def geocode(data)
    end

    def authenticate(data)
    end

    def visit
    end

    def user
      @user ||= begin
        if Ahoy.user_method.respond_to?(:call)
          if Ahoy.user_method.arity == 1
            Ahoy.user_method.call(controller)
          else
            Ahoy.user_method.call(controller, request)
          end
        else
          controller.send(Ahoy.user_method) if controller.respond_to?(Ahoy.user_method, true)
        end
      end
    end

    def exclude?
      (!Ahoy.track_bots && bot?) ||
        exclude_by_method? ||
        (defined?(Rails::HealthController) && controller.is_a?(Rails::HealthController))
    end

    def generate_id
      Ahoy.token_generator.call
    end

    def visit_or_create
      visit
    end

    protected

    def bot?
      unless defined?(@bot)
        @bot = begin
          if request
            if Ahoy.user_agent_parser == :device_detector
              detector = DeviceDetector.new(request.user_agent)
              if Ahoy.bot_detection_version == 2
                detector.bot? || (detector.device_type.nil? && detector.os_name.nil?)
              else
                detector.bot?
              end
            else
              # no need to throw friendly error if browser isn't defined
              # since will error in visit_properties
              Browser.new(request.user_agent).bot?
            end
          else
            false
          end
        end
      end

      @bot
    end

    def exclude_by_method?
      if Ahoy.exclude_method
        if Ahoy.exclude_method.arity == 1
          Ahoy.exclude_method.call(controller)
        else
          Ahoy.exclude_method.call(controller, request)
        end
      else
        false
      end
    end

    def request
      @request ||= @options[:request] || controller.try(:request)
    end

    def controller
      @controller ||= @options[:controller]
    end

    def ahoy
      @ahoy ||= @options[:ahoy]
    end
  end
end
