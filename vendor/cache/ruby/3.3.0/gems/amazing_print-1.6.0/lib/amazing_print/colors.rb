# frozen_string_literal: true

module AmazingPrint
  module Colors
    module_function

    #
    # ANSI color codes:
    #   \e => escape
    #   30 => color base
    #    1 => bright
    #    0 => normal
    #
    # For HTML coloring we use <kbd> tag instead of <span> to require monospace
    # font. Note that beloved <tt> has been removed from HTML5.
    #
    %w[gray red green yellow blue purple cyan white].zip(
      %w[black darkred darkgreen brown navy darkmagenta darkcyan slategray]
    ).each_with_index do |(color, shade), i|
      # NOTE: Format strings are created once only, for performance, and remembered by closures.

      term_bright_seq = "\e[1;#{i + 30}m%s\e[0m"
      html_bright_seq = %(<kbd style="color:#{color}">%s</kbd>)

      define_method color do |str, html = false|
        (html ? html_bright_seq : term_bright_seq) % str
      end

      term_normal_seq = "\e[0;#{i + 30}m%s\e[0m"
      html_normal_seq = %(<kbd style="color:#{shade}">%s</kbd>)

      define_method "#{color}ish" do |str, html = false|
        (html ? html_normal_seq : term_normal_seq) % str
      end
    end
  end
end
