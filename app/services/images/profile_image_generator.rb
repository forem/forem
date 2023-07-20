module Images
  module ProfileImageGenerator
    def self.call
      Rails.root.join("app/assets/images/#{rand(1..40)}.png").open
    end
  end
end
