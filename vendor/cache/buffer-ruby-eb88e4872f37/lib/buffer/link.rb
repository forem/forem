module Buffer
  class Client
    module Link
      def link(options)
        response = get("/links/shares.json", options)
        Buffer::Link.new(response)
      end
    end
  end
end
