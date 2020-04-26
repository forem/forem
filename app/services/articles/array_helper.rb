module Articles
  module ArrayHelper
    def self.first_half(array)
      array[0...(array.length / 2)]
    end

    def self.last_half(array)
      array[(array.length / 2)..array.length]
    end
  end
end
