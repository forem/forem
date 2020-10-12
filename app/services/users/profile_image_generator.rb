module Users
  module ProfileImageGenerator
    EMOJI_IMAGES =
      %w[dog-face_1f436.png
         monkey-face_1f435.png
         unicorn_1f984.png
         mouse-face_1f42d.png
         hamster_1f439.png
         koala_1f428.png
         bear_1f43b.png
         panda_1f43c.png
         penguin_1f427.png
         spouting-whale_1f433.png
         honeybee_1f41d.png
         lion_1f981.png
         tiger-face_1f42f.png
         fox_1f98a.png
         wolf_1f43a.png].freeze
    BACKGROUND_HEXES = %w[#f68d8e #fce289 #f3f096 #55c1ae #88aedc #f8b4d0].freeze
    def self.call
      # This pulls from emojipedia source for the liberally open source twemoji lib.
      # TODO: Make this much more interesting than just emojis.
      "https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/twitter/248/#{EMOJI_IMAGES.sample}"
    end
  end
end
