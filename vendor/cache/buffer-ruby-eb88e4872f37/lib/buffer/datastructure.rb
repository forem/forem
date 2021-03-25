module Buffer
  class UserInfo < Hashie::Mash; end
  class Profile  < Hashie::Mash; end
  class Response < Hashie::Mash; end
  class Update   < Hashie::Mash; end
  class Updates  < Hashie::Mash; end
  class Interaction < Hashie::Mash; end
  class Interactions < Hashie::Mash; end
  class Link < Hashie::Mash; end
  class Info < Hashie::Mash; end

  class Schedule < Hashie::Mash; end
  Schedules = Class.new(Array) do
    def dump
      { schedules: self }.to_json
    end
  end
end
