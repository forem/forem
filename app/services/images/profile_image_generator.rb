module Images
  module ProfileImageGenerator
    SIZE = 400
    INK = "#18181b".freeze

    PALETTES = [
      { bg: "#fef3c7", halo: "#fde68a", sparkle: "#f59e0b", shadow: "#d97706",
        body: "#38bdf8", shirt: "#ec4899", trim: "#fbcfe8", accent: "#34d399", cheek: "#fb7185" },
      { bg: "#dcfce7", halo: "#bbf7d0", sparkle: "#10b981", shadow: "#059669",
        body: "#c084fc", shirt: "#f43f5e", trim: "#fecdd3", accent: "#facc15", cheek: "#f472b6" },
      { bg: "#f3e8ff", halo: "#e9d5ff", sparkle: "#a855f7", shadow: "#7e22ce",
        body: "#fb923c", shirt: "#6366f1", trim: "#c7d2fe", accent: "#2dd4bf", cheek: "#f43f5e" },
      { bg: "#ffe4e6", halo: "#fecdd3", sparkle: "#fb7185", shadow: "#e11d48",
        body: "#2dd4bf", shirt: "#3b82f6", trim: "#bfdbfe", accent: "#facc15", cheek: "#fb7185" },
      { bg: "#e0f2fe", halo: "#bae6fd", sparkle: "#0ea5e9", shadow: "#0284c7",
        body: "#facc15", shirt: "#8b5cf6", trim: "#ddd6fe", accent: "#fb7185", cheek: "#f97316" },
      { bg: "#ecfccb", halo: "#d9f99d", sparkle: "#84cc16", shadow: "#65a30d",
        body: "#f472b6", shirt: "#06b6d4", trim: "#cffafe", accent: "#fde047", cheek: "#e11d48" },
      { bg: "#e0e7ff", halo: "#c7d2fe", sparkle: "#6366f1", shadow: "#4f46e5",
        body: "#4ade80", shirt: "#f97316", trim: "#fed7aa", accent: "#f43f5e", cheek: "#fb7185" },
      { bg: "#ffedd5", halo: "#fed7aa", sparkle: "#f97316", shadow: "#ea580c",
        body: "#818cf8", shirt: "#14b8a6", trim: "#99f6e4", accent: "#f43f5e", cheek: "#fb7185" },
      { bg: "#fce7f3", halo: "#fbcfe8", sparkle: "#ec4899", shadow: "#db2777",
        body: "#67e8f9", shirt: "#4f46e5", trim: "#e0e7ff", accent: "#a3e635", cheek: "#f43f5e" },
      { bg: "#ccfbf1", halo: "#99f6e4", sparkle: "#14b8a6", shadow: "#0d9488",
        body: "#fda4af", shirt: "#7c3aed", trim: "#ede9fe", accent: "#facc15", cheek: "#e11d48" },
      { bg: "#fef9c3", halo: "#fef08a", sparkle: "#eab308", shadow: "#ca8a04",
        body: "#a78bfa", shirt: "#10b981", trim: "#a7f3d0", accent: "#fb7185", cheek: "#f43f5e" },
      { bg: "#dbeafe", halo: "#bfdbfe", sparkle: "#3b82f6", shadow: "#2563eb",
        body: "#fb7185", shirt: "#10b981", trim: "#d1fae5", accent: "#fde047", cheek: "#e11d48" },
      { bg: "#ede9fe", halo: "#ddd6fe", sparkle: "#8b5cf6", shadow: "#6d28d9",
        body: "#86efac", shirt: "#ec4899", trim: "#fce7f3", accent: "#38bdf8", cheek: "#f43f5e" },
      { bg: "#fef2f2", halo: "#fecaca", sparkle: "#ef4444", shadow: "#dc2626",
        body: "#fdba74", shirt: "#2563eb", trim: "#dbeafe", accent: "#34d399", cheek: "#ef4444" },
      { bg: "#ecfeff", halo: "#a5f3fc", sparkle: "#06b6d4", shadow: "#0891b2",
        body: "#e879f9", shirt: "#f59e0b", trim: "#fef3c7", accent: "#38bdf8", cheek: "#e11d48" },
      { bg: "#f0fdf4", halo: "#bbf7d0", sparkle: "#22c55e", shadow: "#16a34a",
        body: "#60a5fa", shirt: "#e11d48", trim: "#ffe4e6", accent: "#facc15", cheek: "#fb7185" },
    ].map(&:freeze).freeze

    BACKDROP_STYLES = %i[bubbles sparkles rings confetti clouds planets].freeze
    OUTFIT_STYLES = %i[crew_sweater hoodie overalls striped_tee star_sweater bandana].freeze
    ARM_STYLES = %i[none none left_wave right_wave both_cheering].freeze
    HEAD_STYLES = %i[squircle mochi bear_cub kitty_ears bunny_ears cloud_puff retro_bot pear_bean].freeze
    TOPPER_STYLES = %i[sprout antenna twin_feelers beanie crown halo curl_tuft party_cone flower_stem].freeze
    EARED_HEAD_TOPPERS = %i[sprout crown halo curl_tuft flower_stem].freeze
    EYE_STYLES = %i[
      kawaii_sparkle happy_arcs wink_sparkle starry_eyes curious_pupils oval_shine cozy_smile visor_eyes
    ].freeze
    ACCESSORY_STYLES = %i[none none none round_glasses brow_beans forehead_star].freeze
    CHEEK_STYLES = %i[oval_blush slash_blush freckle_blush].freeze
    MOUTH_STYLES = %i[open_laugh smile_curve cat_mouth blep_tongue little_o toothy_grin cheerful_v smirk_grin].freeze

    class << self
      def call(seed: nil)
        tempfile = Tempfile.new(["profile_image", ".png"])
        tempfile.close

        traits = select_traits(seed ? Random.new(seed.hash) : Random.new)
        render_avatar(tempfile.path, traits)

        file = File.open(tempfile.path, "rb")
        file.instance_variable_set(:@_tempfile, tempfile)
        file
      rescue MiniMagick::Error, StandardError => e
        Rails.logger.warn("Images::ProfileImageGenerator fallback triggered: #{e.message}")
        fallback_image
      end

      def backfill_missing!(batch_size: 100)
        count = 0
        User.where(profile_image: [nil, ""]).find_each(batch_size: batch_size) do |user|
          user.profile_image = call(seed: user.id)
          user.save!
          count += 1
        end
        count
      end

      private

      def fallback_image
        Rails.root.join("app/assets/images/#{rand(1..40)}.png").open
      end

      def select_traits(rng)
        head = sample_from(HEAD_STYLES, rng)
        topper_pool = %i[bear_cub kitty_ears bunny_ears].include?(head) ? EARED_HEAD_TOPPERS : TOPPER_STYLES
        eyes = sample_from(EYE_STYLES, rng)

        {
          palette: sample_from(PALETTES, rng),
          backdrop: sample_from(BACKDROP_STYLES, rng),
          outfit: sample_from(OUTFIT_STYLES, rng),
          arm: sample_from(ARM_STYLES, rng),
          head: head,
          topper: sample_from(topper_pool, rng),
          eyes: eyes,
          accessory: eyes == :visor_eyes ? :none : sample_from(ACCESSORY_STYLES, rng),
          cheeks: sample_from(CHEEK_STYLES, rng),
          mouth: sample_from(MOUTH_STYLES, rng)
        }
      end

      def sample_from(collection, rng)
        collection[rng.rand(collection.size)]
      end

      def render_avatar(path, traits)
        palette = traits[:palette]

        MiniMagick::Tool::Convert.new do |c|
          c.size "#{SIZE}x#{SIZE}"
          c << "xc:#{palette[:bg]}"

          draw_backdrop(c, traits[:backdrop], palette)
          draw_shadow(c, traits[:head], palette)
          draw_arms(c, traits[:arm], palette)
          draw_outfit(c, traits[:outfit], palette)
          draw_behind_head_features(c, traits[:head], traits[:topper], palette)
          draw_head(c, traits[:head], palette)
          draw_on_head_topper(c, traits[:topper], palette)
          draw_cheeks(c, traits[:cheeks], palette)
          draw_eyes(c, traits[:eyes], palette)
          draw_accessory(c, traits[:accessory], palette)
          draw_mouth(c, traits[:mouth])

          c.strip
          c << path
        end
      end

      def draw_backdrop(canvas, style, palette)
        canvas.stroke "none"
        canvas.fill palette[:halo]
        canvas.draw "circle 200,205 200,48"

        case style
        when :bubbles then draw_bubbles_backdrop(canvas, palette)
        when :sparkles then draw_sparkles_backdrop(canvas, palette)
        when :rings then draw_rings_backdrop(canvas, palette)
        when :confetti then draw_confetti_backdrop(canvas, palette)
        when :clouds then draw_clouds_backdrop(canvas)
        when :planets then draw_planets_backdrop(canvas, palette)
        end
      end

      def draw_bubbles_backdrop(canvas, palette)
        canvas.fill palette[:sparkle]
        canvas.draw "circle 68,95 80,95"
        canvas.draw "circle 332,105 342,105"
        canvas.draw "circle 56,245 64,245"
        canvas.draw "circle 344,238 351,238"
        canvas.fill "#ffffff"
        canvas.draw "circle 92,62 98,62"
        canvas.draw "circle 308,68 314,68"
      end

      def draw_sparkles_backdrop(canvas, palette)
        canvas.fill palette[:sparkle]
        canvas.draw "path '#{four_point_star(72, 92, 16, 6)}'"
        canvas.draw "path '#{four_point_star(328, 98, 14, 5)}'"
        canvas.fill "#ffffff"
        canvas.draw "path '#{four_point_star(336, 225, 11, 4)}'"
        canvas.draw "path '#{four_point_star(64, 232, 11, 4)}'"
        canvas.fill palette[:sparkle]
        canvas.draw "circle 104,58 108,58"
        canvas.draw "circle 296,60 300,60"
      end

      def draw_rings_backdrop(canvas, palette)
        canvas.fill "none"
        canvas.stroke palette[:sparkle]
        canvas.strokewidth "4"
        canvas.draw "circle 200,205 200,32"
        canvas.stroke "none"
        canvas.fill palette[:sparkle]
        canvas.draw "circle 70,88 78,88"
        canvas.draw "circle 330,130 337,130"
      end

      def draw_confetti_backdrop(canvas, palette)
        canvas.fill palette[:sparkle]
        canvas.draw "roundrectangle 58,84 82,96 6,6"
        canvas.draw "roundrectangle 318,92 342,104 6,6"
        canvas.draw "polygon 68,225 80,242 56,242"
        canvas.draw "polygon 334,220 346,237 322,237"
        canvas.fill "#ffffff"
        canvas.draw "circle 96,60 103,60"
        canvas.draw "circle 304,64 311,64"
      end

      def draw_clouds_backdrop(canvas)
        canvas.fill "#ffffff"
        canvas.draw "circle 68,110 86,110"
        canvas.draw "circle 88,104 104,104"
        canvas.draw "circle 106,112 120,112"
        canvas.draw "circle 296,102 312,102"
        canvas.draw "circle 316,96 332,96"
        canvas.draw "circle 334,104 348,104"
      end

      def draw_planets_backdrop(canvas, palette)
        canvas.fill palette[:sparkle]
        canvas.draw "circle 72,96 86,96"
        canvas.fill "none"
        canvas.stroke "#ffffff"
        canvas.strokewidth "4"
        canvas.draw "ellipse 72,96 24,7 0,360"
        canvas.stroke "none"
        canvas.fill "#ffffff"
        canvas.draw "circle 330,96 338,96"
        canvas.fill palette[:sparkle]
        canvas.draw "circle 340,232 347,232"
      end

      def four_point_star(center_x, center_y, r_out, r_in)
        "M #{center_x},#{center_y - r_out} Q #{center_x + r_in},#{center_y - r_in} #{center_x + r_out},#{center_y} " \
          "Q #{center_x + r_in},#{center_y + r_in} #{center_x},#{center_y + r_out} " \
          "Q #{center_x - r_in},#{center_y + r_in} #{center_x - r_out},#{center_y} " \
          "Q #{center_x - r_in},#{center_y - r_in} #{center_x},#{center_y - r_out} Z"
      end

      def five_point_star(center_x, center_y, r_out, r_in)
        pts = (0...10).map do |i|
          angle = (-90 + (i * 36)) * Math::PI / 180.0
          radius = i.even? ? r_out : r_in
          "#{(center_x + (radius * Math.cos(angle))).round(1)},#{(center_y + (radius * Math.sin(angle))).round(1)}"
        end
        "M #{pts.first} L #{pts[1..].join(' L ')} Z"
      end

      def draw_shadow(canvas, head, palette)
        canvas.stroke "none"
        canvas.fill palette[:shadow]
        canvas.draw "path 'M 103,410 C 103,288 145,250 208,250 C 271,250 313,288 313,410 Z'"
        if %i[mochi pear_bean].include?(head)
          canvas.draw "ellipse 207,190 92,74 0,360"
        else
          canvas.draw "roundrectangle 117,115 297,264 56,56"
        end
      end

      def draw_arms(canvas, arm, palette)
        return if arm == :none

        canvas.stroke INK
        canvas.strokewidth "9"
        canvas.fill palette[:body]
        if %i[left_wave both_cheering].include?(arm)
          canvas.draw "stroke-linejoin round stroke-linecap round " \
                      "path 'M 118,295 C 68,270 54,224 78,206 C 94,194 114,226 128,268 Z'"
        end
        return unless %i[right_wave both_cheering].include?(arm)

        canvas.draw "stroke-linejoin round stroke-linecap round " \
                    "path 'M 282,295 C 332,270 346,224 322,206 C 306,194 286,226 272,268 Z'"
      end

      def draw_outfit(canvas, outfit, palette)
        canvas.stroke INK
        canvas.strokewidth "9"
        canvas.fill(outfit == :overalls ? palette[:trim] : palette[:shirt])
        canvas.draw "stroke-linejoin round stroke-linecap round " \
                    "path 'M 95,410 C 95,282 140,242 200,242 C 260,242 305,282 305,410 Z'"

        case outfit
        when :crew_sweater then draw_collar(canvas, palette[:trim])
        when :hoodie then draw_hoodie_details(canvas, palette)
        when :overalls then draw_overalls_details(canvas, palette)
        when :striped_tee then draw_striped_tee_details(canvas, palette)
        when :star_sweater then draw_star_sweater_details(canvas, palette)
        when :bandana then draw_bandana_details(canvas, palette)
        end
      end

      def draw_collar(canvas, color)
        canvas.fill color
        canvas.draw "stroke-linejoin round path 'M 152,254 Q 200,294 248,254 Q 225,242 200,242 Q 175,242 152,254 Z'"
      end

      def draw_hoodie_details(canvas, palette)
        canvas.fill palette[:trim]
        canvas.draw "stroke-linejoin round path 'M 142,256 Q 200,302 258,256 Q 230,242 200,242 Q 170,242 142,256 Z'"
        canvas.fill "none"
        canvas.strokewidth "7"
        canvas.draw "stroke-linecap round path 'M 176,276 L 176,332'"
        canvas.draw "stroke-linecap round path 'M 224,276 L 224,332'"
        canvas.fill palette[:accent]
        canvas.strokewidth "6"
        canvas.draw "circle 176,336 176,328"
        canvas.draw "circle 224,336 224,328"
      end

      def draw_overalls_details(canvas, palette)
        canvas.fill palette[:shirt]
        canvas.draw "stroke-linejoin round " \
                    "path 'M 146,250 L 168,250 L 168,325 L 232,325 L 232,250 L 254,250 L 262,410 L 138,410 Z'"
        canvas.fill palette[:accent]
        canvas.strokewidth "6"
        canvas.draw "circle 157,308 157,299"
        canvas.draw "circle 243,308 243,299"
      end

      def draw_striped_tee_details(canvas, palette)
        canvas.fill palette[:trim]
        canvas.draw "stroke-linejoin round path 'M 108,315 L 292,315 L 298,348 L 102,348 Z'"
        draw_collar(canvas, palette[:trim])
      end

      def draw_star_sweater_details(canvas, palette)
        draw_collar(canvas, palette[:trim])
        canvas.fill palette[:accent]
        canvas.strokewidth "6"
        canvas.draw "stroke-linejoin round path '#{five_point_star(200, 336, 26, 12)}'"
      end

      def draw_bandana_details(canvas, palette)
        canvas.fill palette[:accent]
        canvas.draw "stroke-linejoin round path 'M 136,252 L 200,326 L 264,252 Q 232,242 200,242 Q 168,242 136,252 Z'"
      end

      def draw_behind_head_features(canvas, head, topper, palette)
        draw_head_ears(canvas, head, palette)
        draw_stem_toppers(canvas, topper, palette)
      end

      def draw_head_ears(canvas, head, palette)
        canvas.stroke INK
        canvas.strokewidth "9"

        case head
        when :bear_cub
          canvas.fill palette[:body]
          canvas.draw "circle 126,116 126,84"
          canvas.draw "circle 274,116 274,84"
          canvas.stroke "none"
          canvas.fill palette[:cheek]
          canvas.draw "circle 126,116 126,98"
          canvas.draw "circle 274,116 274,98"
        when :kitty_ears
          canvas.fill palette[:body]
          canvas.draw "stroke-linejoin round path 'M 114,148 L 104,76 L 168,112 Z'"
          canvas.draw "stroke-linejoin round path 'M 286,148 L 296,76 L 232,112 Z'"
          canvas.stroke "none"
          canvas.fill palette[:cheek]
          canvas.draw "polygon 122,132 116,94 152,114"
          canvas.draw "polygon 278,132 284,94 248,114"
        when :bunny_ears
          canvas.fill palette[:body]
          canvas.draw "stroke-linejoin round path 'M 126,120 C 116,42 160,42 158,118 Z'"
          canvas.draw "stroke-linejoin round path 'M 274,120 C 284,42 240,42 242,118 Z'"
          canvas.stroke "none"
          canvas.fill palette[:cheek]
          canvas.draw "ellipse 140,84 8,22 0,360"
          canvas.draw "ellipse 260,84 8,22 0,360"
        when :retro_bot
          canvas.fill palette[:accent]
          canvas.draw "roundrectangle 92,150 116,188 8,8"
          canvas.draw "roundrectangle 284,150 308,188 8,8"
        end
      end

      def draw_stem_toppers(canvas, topper, palette)
        canvas.stroke INK
        canvas.strokewidth "9"

        case topper
        when :sprout
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 200,114 L 200,72'"
          canvas.fill palette[:accent]
          canvas.draw "stroke-linejoin round path 'M 200,72 C 166,50 148,78 180,90 C 192,94 200,82 200,72 Z'"
          canvas.draw "stroke-linejoin round path 'M 200,72 C 234,50 252,78 220,90 C 208,94 200,82 200,72 Z'"
        when :antenna
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 200,114 L 200,66'"
          canvas.fill palette[:accent]
          canvas.draw "circle 200,56 200,38"
          canvas.stroke "none"
          canvas.fill "#ffffff"
          canvas.draw "circle 195,51 195,46"
        when :twin_feelers
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 178,114 Q 162,74 146,64'"
          canvas.draw "stroke-linecap round path 'M 222,114 Q 238,74 254,64'"
          canvas.fill palette[:accent]
          canvas.draw "circle 144,62 144,49"
          canvas.draw "circle 256,62 256,49"
        when :flower_stem
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 200,114 L 200,72'"
          canvas.fill palette[:trim]
          [[184, 64], [216, 64], [200, 48], [200, 80]].each do |fx, fy|
            canvas.draw "circle #{fx},#{fy} #{fx},#{fy - 12}"
          end
          canvas.fill palette[:accent]
          canvas.draw "circle 200,64 200,53"
        end
      end

      def draw_head(canvas, head, palette)
        canvas.stroke INK
        canvas.strokewidth "9"
        canvas.fill palette[:body]

        case head
        when :squircle, :bear_cub, :kitty_ears, :bunny_ears
          canvas.draw "roundrectangle 110,108 290,258 56,56"
        when :mochi
          canvas.draw "stroke-linejoin round path 'M 104,190 C 104,118 144,106 200,106 C 256,106 296,118 296,190 " \
                      "C 296,248 258,260 200,260 C 142,260 104,248 104,190 Z'"
        when :cloud_puff
          canvas.draw "stroke-linejoin round path 'M 112,186 C 96,162 110,128 138,124 C 152,98 188,96 200,110 " \
                      "C 212,96 248,98 262,124 C 290,128 304,162 288,186 C 302,216 282,250 252,252 " \
                      "C 232,266 168,266 148,252 C 118,250 98,216 112,186 Z'"
        when :retro_bot
          canvas.draw "roundrectangle 110,108 290,258 38,38"
          canvas.strokewidth "6"
          canvas.fill palette[:bg]
          canvas.draw "roundrectangle 128,128 272,240 24,24"
        when :pear_bean
          canvas.draw "stroke-linejoin round path 'M 122,154 C 122,112 154,104 200,104 C 246,104 278,112 278,154 " \
                      "C 298,192 296,258 200,258 C 104,258 102,192 122,154 Z'"
        end

        return if head == :retro_bot

        canvas.fill "none"
        canvas.stroke "#ffffff"
        canvas.strokewidth "7"
        canvas.draw "stroke-linecap round path 'M 134,142 Q 144,124 168,124'"
      end

      def draw_on_head_topper(canvas, topper, palette)
        canvas.stroke INK
        canvas.strokewidth "9"

        case topper
        when :beanie
          canvas.fill palette[:accent]
          canvas.draw "stroke-linejoin round path 'M 120,132 C 124,78 276,78 280,132 Z'"
          canvas.fill palette[:shirt]
          canvas.draw "roundrectangle 114,118 286,142 12,12"
          canvas.fill palette[:trim]
          canvas.draw "circle 200,72 200,54"
        when :crown
          canvas.fill palette[:accent]
          canvas.draw "stroke-linejoin round " \
                      "path 'M 164,112 L 158,70 L 182,90 L 200,62 L 218,90 L 242,70 L 236,112 Z'"
        when :halo
          canvas.fill "none"
          canvas.stroke palette[:accent]
          canvas.strokewidth "11"
          canvas.draw "ellipse 200,68 48,13 0,360"
          canvas.stroke INK
          canvas.strokewidth "4"
          canvas.draw "ellipse 200,68 52,16 0,360"
        when :curl_tuft
          canvas.fill palette[:body]
          canvas.draw "stroke-linejoin round stroke-linecap round " \
                      "path 'M 184,112 C 176,72 218,62 222,88 C 224,102 206,108 198,98'"
        when :party_cone
          canvas.fill palette[:accent]
          canvas.draw "stroke-linejoin round path 'M 164,110 L 200,48 L 236,110 Z'"
          canvas.fill palette[:trim]
          canvas.draw "circle 200,44 200,31"
        end
      end

      def draw_cheeks(canvas, style, palette)
        canvas.stroke "none"
        canvas.fill palette[:cheek]
        canvas.draw "ellipse 146,204 14,9 0,360"
        canvas.draw "ellipse 254,204 14,9 0,360"

        case style
        when :slash_blush
          canvas.stroke INK
          canvas.strokewidth "3"
          canvas.draw "line 141,200 147,208"
          canvas.draw "line 148,200 154,208"
          canvas.draw "line 247,200 253,208"
          canvas.draw "line 254,200 260,208"
        when :freckle_blush
          canvas.fill INK
          canvas.draw "circle 142,192 142,189"
          canvas.draw "circle 151,194 151,191"
          canvas.draw "circle 249,194 249,191"
          canvas.draw "circle 258,192 258,189"
        end
      end

      def draw_eyes(canvas, style, palette)
        case style
        when :kawaii_sparkle then draw_kawaii_sparkle_eyes(canvas)
        when :happy_arcs then draw_happy_arc_eyes(canvas)
        when :wink_sparkle then draw_wink_sparkle_eyes(canvas)
        when :starry_eyes then draw_starry_eyes(canvas)
        when :curious_pupils then draw_curious_pupil_eyes(canvas)
        when :oval_shine then draw_oval_shine_eyes(canvas)
        when :cozy_smile then draw_cozy_smile_eyes(canvas)
        when :visor_eyes then draw_visor_eyes(canvas, palette)
        end
      end

      def draw_kawaii_sparkle_eyes(canvas)
        canvas.stroke "none"
        canvas.fill INK
        canvas.draw "circle 162,178 162,162"
        canvas.draw "circle 238,178 238,162"
        canvas.fill "#ffffff"
        canvas.draw "circle 157,173 157,167"
        canvas.draw "circle 233,173 233,167"
        canvas.draw "circle 167,183 167,180"
        canvas.draw "circle 243,183 243,180"
      end

      def draw_happy_arc_eyes(canvas)
        canvas.fill "none"
        canvas.stroke INK
        canvas.strokewidth "8"
        canvas.draw "stroke-linecap round path 'M 146,182 Q 162,160 178,182'"
        canvas.draw "stroke-linecap round path 'M 222,182 Q 238,160 254,182'"
      end

      def draw_wink_sparkle_eyes(canvas)
        canvas.stroke "none"
        canvas.fill INK
        canvas.draw "circle 162,178 162,162"
        canvas.fill "#ffffff"
        canvas.draw "circle 157,173 157,167"
        canvas.draw "circle 167,183 167,180"
        canvas.fill "none"
        canvas.stroke INK
        canvas.strokewidth "8"
        canvas.draw "stroke-linecap round stroke-linejoin round path 'M 222,168 L 244,178 L 222,188'"
      end

      def draw_starry_eyes(canvas)
        canvas.stroke "none"
        canvas.fill INK
        canvas.draw "circle 162,178 162,161"
        canvas.draw "circle 238,178 238,161"
        canvas.fill "#ffffff"
        canvas.draw "path '#{four_point_star(160, 176, 9, 3)}'"
        canvas.draw "path '#{four_point_star(236, 176, 9, 3)}'"
      end

      def draw_curious_pupil_eyes(canvas)
        canvas.stroke INK
        canvas.strokewidth "6"
        canvas.fill "#ffffff"
        canvas.draw "circle 162,178 162,161"
        canvas.draw "circle 238,178 238,161"
        canvas.stroke "none"
        canvas.fill INK
        canvas.draw "circle 166,178 166,168"
        canvas.draw "circle 234,178 234,168"
        canvas.fill "#ffffff"
        canvas.draw "circle 163,174 163,171"
        canvas.draw "circle 231,174 231,171"
      end

      def draw_oval_shine_eyes(canvas)
        canvas.stroke "none"
        canvas.fill INK
        canvas.draw "ellipse 162,178 12,17 0,360"
        canvas.draw "ellipse 238,178 12,17 0,360"
        canvas.fill "#ffffff"
        canvas.draw "ellipse 158,171 5,6 0,360"
        canvas.draw "ellipse 234,171 5,6 0,360"
      end

      def draw_cozy_smile_eyes(canvas)
        canvas.fill "none"
        canvas.stroke INK
        canvas.strokewidth "8"
        canvas.draw "stroke-linecap round path 'M 146,178 C 152,164 172,164 178,178'"
        canvas.draw "stroke-linecap round path 'M 222,178 C 228,164 248,164 254,178'"
        canvas.strokewidth "6"
        canvas.draw "stroke-linecap round path 'M 142,174 L 136,168'"
        canvas.draw "stroke-linecap round path 'M 258,174 L 264,168'"
      end

      def draw_visor_eyes(canvas, palette)
        canvas.stroke INK
        canvas.strokewidth "7"
        canvas.fill palette[:accent]
        canvas.draw "roundrectangle 136,162 264,192 15,15"
        canvas.stroke "none"
        canvas.fill "#ffffff"
        canvas.draw "roundrectangle 148,168 178,175 3,3"
      end

      def draw_accessory(canvas, style, palette)
        case style
        when :round_glasses
          canvas.fill "none"
          canvas.stroke INK
          canvas.strokewidth "6"
          canvas.draw "circle 162,178 162,154"
          canvas.draw "circle 238,178 238,154"
          canvas.draw "line 186,178 214,178"
        when :brow_beans
          canvas.stroke "none"
          canvas.fill INK
          canvas.draw "roundrectangle 148,148 174,156 4,4"
          canvas.draw "roundrectangle 226,148 252,156 4,4"
        when :forehead_star
          canvas.stroke INK
          canvas.strokewidth "4"
          canvas.fill palette[:accent]
          canvas.draw "path '#{four_point_star(200, 144, 12, 5)}'"
        end
      end

      def draw_mouth(canvas, style)
        canvas.stroke INK
        canvas.strokewidth "7"

        case style
        when :open_laugh
          canvas.fill "#f43f5e"
          canvas.draw "stroke-linejoin round path 'M 182,198 L 218,198 C 218,226 182,226 182,198 Z'"
        when :smile_curve
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 183,200 Q 200,218 217,200'"
        when :cat_mouth
          canvas.fill "none"
          canvas.draw "stroke-linecap round stroke-linejoin round " \
                      "path 'M 178,200 Q 189,215 200,200 Q 211,215 222,200'"
        when :blep_tongue
          canvas.fill "#fb7185"
          canvas.draw "stroke-linejoin round path 'M 194,204 C 194,226 216,226 216,204 Z'"
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 182,200 Q 200,214 218,200'"
        when :little_o
          canvas.fill "#f43f5e"
          canvas.draw "ellipse 200,208 9,11 0,360"
        when :toothy_grin
          canvas.fill "#f43f5e"
          canvas.draw "stroke-linejoin round path 'M 180,196 L 220,196 C 220,224 180,224 180,196 Z'"
          canvas.fill "#ffffff"
          canvas.strokewidth "5"
          canvas.draw "roundrectangle 193,196 207,207 3,3"
        when :cheerful_v
          canvas.fill "none"
          canvas.draw "stroke-linecap round stroke-linejoin round path 'M 185,198 L 200,214 L 215,198'"
        when :smirk_grin
          canvas.fill "none"
          canvas.draw "stroke-linecap round path 'M 183,204 Q 202,216 218,196'"
        end
      end
    end
  end
end
