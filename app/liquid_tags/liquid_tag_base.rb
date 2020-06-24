class LiquidTagBase < Liquid::Tag
  def self.script
    ""
  end

  def detect_in_context(key, context)
    # Pulls the value of the specified key out of context.environments which is
    # an Array of Hashes. Otherwise, it returns nil.
    context.environments.detect { |c| c[key] }.try(:[], key)
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, "").
      gsub(/\n/m, " ").
      gsub(/>\n{1,}</m, "><").
      strip.
      html_safe
  end
end
