class LiquidTagBase < Liquid::Tag
  def self.script
    ''
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, '')
         .gsub(/\n/m, ' ')
         .gsub(/>\n{1,}</m, '><')
         .strip
         .html_safe
  end
end
