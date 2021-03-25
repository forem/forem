module Buffer
  class Client
    module User
      def user_info(options = {})
        Buffer::UserInfo.new(get("/user.json"))
      end
    end
  end
end
