module CarrierWave
  module BombShelter
    def image_type_whitelist
      [:jpeg, :png, :gif, :webp]
    end
  end
end