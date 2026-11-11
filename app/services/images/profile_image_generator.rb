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
      rescue StandardError => e
        tempfile&.unlink
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
        File.binwrite(path, ForemNative.render_profile_image_png(traits))
      end
    end
  end
end
