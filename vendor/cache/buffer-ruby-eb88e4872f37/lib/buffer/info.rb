module Buffer
  class Client
    module Info
      def info
        response = get("/info/configuration.json")
        Buffer::Info.new(response)
      end
    end
  end
end
