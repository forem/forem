module Users
  module ProfileImageGenerator
    def self.call
      File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png"))
    end
  end
end
