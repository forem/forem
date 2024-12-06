# frozen_string_literal: true

require 'stringio'
require_relative '../mini_histogram' # allows people to require 'mini_histogram/plot' directly

# Plots the histogram in unicode characters
#
# Thanks to https://github.com/red-data-tools/unicode_plot.rb
# it could not be used because the dependency enumerable-statistics has a hard
# lock on a specific version of Ruby and this library needs to support older Rubies
#
# Example:
#
#   require 'mini_histogram/plot'
#   array = 50.times.map { rand(11.2..11.6) }
#   histogram = MiniHistogram.new(array)
#   puts histogram.plot => Generates a plot
#
class MiniHistogram

  # This is an object that holds a histogram
  # and it's corresponding plot options
  #
  # Example:
  #
  #   x = PlotValue.new
  #   x.values = [1,2,3,4,5]
  #   x.options = {xlabel: "random"}
  #
  #   x.plot # => Generates a histogram plot with these values and options
  class PlotValue
    attr_accessor :histogram, :options

    def initialize
      @histogram = nil
      @options = {}
    end

    def plot
      raise "@histogram cannot be empty set via `values=` or `histogram=` methods" if @histogram.nil?

      @histogram.plot(**@options)
    end

    def values=(values)
      @histogram = MiniHistogram.new(values)
    end

    def self.dual_plot(plot_a, plot_b)
      a_lines = plot_a.to_s.lines
      b_lines = plot_b.to_s.lines

      max_length = a_lines.map(&:length).max

      side_by_side = String.new("")
      a_lines.each_index do |i|
        side_by_side << a_lines[i].chomp.ljust(max_length) # Remove newline, ensure same length
        side_by_side << b_lines[i]
      end

      return side_by_side
    end
  end
  private_constant :PlotValue

  def self.dual_plot
    a = PlotValue.new
    b = PlotValue.new

    yield a, b

    if b.options[:ylabel] == a.options[:ylabel]
      b.options[:ylabel] = nil
    end

    MiniHistogram.set_average_edges!(a.histogram, b.histogram)
    PlotValue.dual_plot(a.plot, b.plot)
  end

  def plot(
    nbins: nil,
    closed: :left,
    symbol: "▇",
    **kw)
    hist = self.histogram(*[nbins].compact, closed: closed)
    edge, counts = hist.edge, hist.weights
    labels = []
    bin_width = edge[1] - edge[0]
    pad_left, pad_right = 0, 0
    (0 ... edge.length).each do |i|
      val1 = float_round_log10(edge[i], bin_width)
      val2 = float_round_log10(val1 + bin_width, bin_width)
      a1 = val1.to_s.split('.', 2).map(&:length)
      a2 = val2.to_s.split('.', 2).map(&:length)
      pad_left  = [pad_left,  a1[0], a2[0]].max
      pad_right = [pad_right, a1[1], a2[1]].max
    end
    l_str = hist.closed == :right ? "(" : "["
    r_str = hist.closed == :right ? "]" : ")"
    counts.each_with_index do |n, i|
      val1 = float_round_log10(edge[i], bin_width)
      val2 = float_round_log10(val1 + bin_width, bin_width)
      a1 = val1.to_s.split('.', 2).map(&:length)
      a2 = val2.to_s.split('.', 2).map(&:length)
      labels[i] = "\e[90m#{l_str}\e[0m" +
                  (" " * (pad_left - a1[0])) +
                  val1.to_s +
                  (" " * (pad_right - a1[1])) +
                  "\e[90m, \e[0m" +
                  (" " * (pad_left - a2[0])) +
                  val2.to_s +
                  (" " * (pad_right - a2[1])) +
                  "\e[90m#{r_str}\e[0m"
    end
    xscale = kw.delete(:xscale)
    xlabel = kw.delete(:xlabel) || MiniUnicodePlot::ValueTransformer.transform_name(xscale, "Frequency")
    barplot(labels, counts,
            symbol: symbol,
            xscale: xscale,
            xlabel: xlabel,
            **kw)
  end

  ## Begin copy/pasta from unicode_plot.rb with some slight modifications
  private def barplot(
    *args,
    width: 40,
    color: :green,
    symbol: "■",
    border: :barplot,
    xscale: nil,
    xlabel: nil,
    data: nil,
    **kw)
    case args.length
    when 0
      data = Hash(data)
      keys = data.keys.map(&:to_s)
      heights = data.values
    when 2
      keys = Array(args[0])
      heights = Array(args[1])
    else
      raise ArgumentError, "invalid arguments"
    end

    unless keys.length == heights.length
      raise ArgumentError, "The given vectors must be of the same length"
    end
    unless heights.min >= 0
      raise ArgumentError, "All values have to be positive. Negative bars are not supported."
    end

    xlabel ||= ValueTransformer.transform_name(xscale)
    plot = MiniUnicodePlot::Barplot.new(heights, width, color, symbol, xscale,
                       border: border, xlabel: xlabel,
                       **kw)
    keys.each_with_index do |key, i|
      plot.annotate_row!(:l, i, key)
    end

    plot
  end

  private def float_round_log10(x, m)
    if x == 0
      0.0
    elsif x > 0
      x.round(ceil_neg_log10(m) + 1).to_f
    else
      -(-x).round(ceil_neg_log10(m) + 1).to_f
    end
  end

  private def ceil_neg_log10(x)
    if roundable?(-Math.log10(x))
      (-Math.log10(x)).ceil
    else
      (-Math.log10(x)).floor
    end
  end

  INT64_MIN = -9223372036854775808
  INT64_MAX =  9223372036854775807
  private def roundable?(x)
    x.to_i == x && INT64_MIN <= x && x < INT64_MAX
  end

  module MiniUnicodePlot
    module ValueTransformer
      PREDEFINED_TRANSFORM_FUNCTIONS = {
        log: Math.method(:log),
        ln: Math.method(:log),
        log10: Math.method(:log10),
        lg: Math.method(:log10),
        log2: Math.method(:log2),
        lb: Math.method(:log2),
      }.freeze

      def transform_values(func, values)
        return values unless func

        unless func.respond_to?(:call)
          func = PREDEFINED_TRANSFORM_FUNCTIONS[func]
          unless func.respond_to?(:call)
            raise ArgumentError, "func must be callable"
          end
        end

        case values
        when Numeric
          func.(values)
        else
          values.map(&func)
        end
      end

      module_function def transform_name(func, basename="")
        return basename unless func
        case func
        when String, Symbol
          name = func
        when ->(f) { f.respond_to?(:name) }
          name = func.name
        else
          name = "custom"
        end
        "#{basename} [#{name}]"
      end
    end


    module BorderMaps
      BORDER_SOLID = {
        tl: "┌",
        tr: "┐",
        bl: "└",
        br: "┘",
        t:  "─",
        l:  "│",
        b:  "─",
        r:  "│"
      }.freeze

      BORDER_CORNERS = {
        tl: "┌",
        tr: "┐",
        bl: "└",
        br: "┘",
        t:  " ",
        l:  " ",
        b:  " ",
        r:  " ",
      }.freeze

      BORDER_BARPLOT = {
        tl: "┌",
        tr: "┐",
        bl: "└",
        br: "┘",
        t:  " ",
        l:  "┤",
        b:  " ",
        r:  " ",
      }.freeze
    end

    BORDER_MAP = {
      solid:   BorderMaps::BORDER_SOLID,
      corners: BorderMaps::BORDER_CORNERS,
      barplot: BorderMaps::BORDER_BARPLOT,
    }.freeze

    module StyledPrinter
      TEXT_COLORS = {
        black:         "\033[30m",
        red:           "\033[31m",
        green:         "\033[32m",
        yellow:        "\033[33m",
        blue:          "\033[34m",
        magenta:       "\033[35m",
        cyan:          "\033[36m",
        white:         "\033[37m",
        gray:          "\033[90m",
        light_black:   "\033[90m",
        light_red:     "\033[91m",
        light_green:   "\033[92m",
        light_yellow:  "\033[93m",
        light_blue:    "\033[94m",
        light_magenta: "\033[95m",
        light_cyan:    "\033[96m",
        normal:        "\033[0m",
        default:       "\033[39m",
        bold:          "\033[1m",
        underline:     "\033[4m",
        blink:         "\033[5m",
        reverse:       "\033[7m",
        hidden:        "\033[8m",
        nothing:       "",
      }

      0.upto(255) do |i|
        TEXT_COLORS[i] = "\033[38;5;#{i}m"
      end

      TEXT_COLORS.freeze

      DISABLE_TEXT_STYLE = {
        bold:      "\033[22m",
        underline: "\033[24m",
        blink:     "\033[25m",
        reverse:   "\033[27m",
        hidden:    "\033[28m",
        normal:    "",
        default:   "",
        nothing:   "",
      }.freeze

      COLOR_ENCODE = {
        normal:  0b000,
        blue:    0b001,
        red:     0b010,
        magenta: 0b011,
        green:   0b100,
        cyan:    0b101,
        yellow:  0b110,
        white:   0b111
      }.freeze

      COLOR_DECODE = COLOR_ENCODE.map {|k, v| [v, k] }.to_h.freeze

      def print_styled(out, *args, bold: false, color: :normal)
        return out.print(*args) unless color?(out)

        str = StringIO.open {|sio| sio.print(*args); sio.close; sio.string }
        color = :nothing if bold && color == :bold
        enable_ansi = TEXT_COLORS.fetch(color, TEXT_COLORS[:default]) +
                      (bold ? TEXT_COLORS[:bold] : "")
        disable_ansi = (bold ? DISABLE_TEXT_STYLE[:bold] : "") +
                       DISABLE_TEXT_STYLE.fetch(color, TEXT_COLORS[:default])
        first = true
        StringIO.open do |sio|
          str.each_line do |line|
            sio.puts unless first
            first = false
            continue if line.empty?
            sio.print(enable_ansi, line, disable_ansi)
          end
          sio.close
          out.print(sio.string)
        end
      end

      def print_color(out, color, *args)
        color = COLOR_DECODE[color]
        print_styled(out, *args, color: color)
      end

      def color?(out)
        (out && out.tty?) || false
      end
    end

    module BorderPrinter
      include StyledPrinter

      def print_border_top(out, padding, length, border=:solid, color: :light_black)
        return if border == :none
        b = BORDER_MAP[border]
        print_styled(out, padding, b[:tl], b[:t] * length, b[:tr], color: color)
      end

      def print_border_bottom(out, padding, length, border=:solid, color: :light_black)
        return if border == :none
        b = BORDER_MAP[border]
        print_styled(out, padding, b[:bl], b[:b] * length, b[:br], color: color)
      end
    end

    class Renderer
      include BorderPrinter

      def self.render(out, plot)
        new(plot).render(out)
      end

      def initialize(plot)
        @plot = plot
        @out = nil
      end

      attr_reader :plot
      attr_reader :out

      def render(out)
        @out = out
        init_render

        render_top
        render_rows
        render_bottom
      end

      private

      def render_top
        # plot the title and the top border
        print_title(@border_padding, plot.title, p_width: @border_length, color: :bold)
        puts if plot.title_given?

        if plot.show_labels?
          topleft_str  = plot.decorations.fetch(:tl, "")
          topleft_col  = plot.colors_deco.fetch(:tl, :light_black)
          topmid_str   = plot.decorations.fetch(:t, "")
          topmid_col   = plot.colors_deco.fetch(:t, :light_black)
          topright_str = plot.decorations.fetch(:tr, "")
          topright_col = plot.colors_deco.fetch(:tr, :light_black)

          if topleft_str != "" || topright_str != "" || topmid_str != ""
              topleft_len  = topleft_str.length
              topmid_len   = topmid_str.length
              topright_len = topright_str.length
              print_styled(out, @border_padding, topleft_str, color: topleft_col)
              cnt = (@border_length / 2.0 - topmid_len / 2.0 - topleft_len).round
              pad = cnt > 0 ? " " * cnt : ""
              print_styled(out, pad, topmid_str, color: topmid_col)
              cnt = @border_length - topright_len - topleft_len - topmid_len + 2 - cnt
              pad = cnt > 0 ? " " * cnt : ""
              print_styled(out, pad, topright_str, "\n", color: topright_col)
          end
        end

        print_border_top(out, @border_padding, @border_length, plot.border)
        print(" " * @max_len_r, @plot_padding, "\n")
      end

      # render all rows
      def render_rows
        (0 ... plot.n_rows).each {|row| render_row(row) }
      end

      def render_row(row)
        # Current labels to left and right of the row and their length
        left_str  = plot.labels_left.fetch(row, "")
        left_col  = plot.colors_left.fetch(row, :light_black)
        right_str = plot.labels_right.fetch(row, "")
        right_col = plot.colors_right.fetch(row, :light_black)
        left_len  = nocolor_string(left_str).length
        right_len = nocolor_string(right_str).length

        unless color?(out)
          left_str  = nocolor_string(left_str)
          right_str = nocolor_string(right_str)
        end

        # print left annotations
        print(" " * plot.margin)
        if plot.show_labels?
          if row == @y_lab_row
            # print ylabel
            print_styled(out, plot.ylabel, color: :normal)
            print(" " * (@max_len_l - plot.ylabel_length - left_len))
          else
            # print padding to fill ylabel length
            print(" " * (@max_len_l - left_len))
          end
          # print the left annotation
          print_styled(out, left_str, color: left_col)
        end

        # print left border
        print_styled(out, @plot_padding, @b[:l], color: :light_black)

        # print canvas row
        plot.print_row(out, row)

        #print right label and padding
        print_styled(out, @b[:r], color: :light_black)
        if plot.show_labels?
          print(@plot_padding)
          print_styled(out, right_str, color: right_col)
          print(" " * (@max_len_r - right_len))
        end
        puts
      end

      def render_bottom
        # draw bottom border and bottom labels
        print_border_bottom(out, @border_padding, @border_length, plot.border)
        print(" " * @max_len_r, @plot_padding)
        if plot.show_labels?
          botleft_str  = plot.decorations.fetch(:bl, "")
          botleft_col  = plot.colors_deco.fetch(:bl, :light_black)
          botmid_str   = plot.decorations.fetch(:b, "")
          botmid_col   = plot.colors_deco.fetch(:b, :light_black)
          botright_str = plot.decorations.fetch(:br, "")
          botright_col = plot.colors_deco.fetch(:br, :light_black)

          if botleft_str != "" || botright_str != "" || botmid_str != ""
            puts
            botleft_len  = botleft_str.length
            botmid_len   = botmid_str.length
            botright_len = botright_str.length
            print_styled(out, @border_padding, botleft_str, color: botleft_col)
            cnt = (@border_length / 2.0 - botmid_len / 2.0 - botleft_len).round
            pad = cnt > 0 ? " " * cnt : ""
            print_styled(out, pad, botmid_str, color: botmid_col)
            cnt = @border_length - botright_len - botleft_len - botmid_len + 2 - cnt
            pad = cnt > 0 ? " " * cnt : ""
            print_styled(out, pad, botright_str, color: botright_col)
          end

          # abuse the print_title function to print the xlabel. maybe refactor this
          puts if plot.xlabel_given?
          print_title(@border_padding, plot.xlabel, p_width: @border_length)
        end
      end

      def init_render
        @b = BORDER_MAP[plot.border]
        @border_length = plot.n_columns

        # get length of largest strings to the left and right
        @max_len_l = plot.show_labels? && !plot.labels_left.empty? ?
          plot.labels_left.each_value.map {|l| nocolor_string(l).length }.max :
          0
        @max_len_r = plot.show_labels? && !plot.labels_right.empty? ?
          plot.labels_right.each_value.map {|l| nocolor_string(l).length }.max :
          0
        if plot.show_labels? && plot.ylabel_given?
          @max_len_l += plot.ylabel_length + 1
        end

        # offset where the plot (incl border) begins
        @plot_offset = @max_len_l + plot.margin + plot.padding

        # padding-string from left to border
        @plot_padding = " " * plot.padding

        # padding-string between labels and border
        @border_padding = " " * @plot_offset

        # compute position of ylabel
        @y_lab_row = (plot.n_rows / 2.0).round - 1
      end

      def print_title(padding, title, p_width: 0, color: :normal)
        return unless title && title != ""
        offset = (p_width / 2.0 - title.length / 2.0).round
        offset = [offset, 0].max
        tpad = " " * offset
        print_styled(out, padding, tpad, title, color: color)
      end

      def print(*args)
        out.print(*args)
      end

      def puts(*args)
        out.puts(*args)
      end

      def nocolor_string(str)
        str.to_s.gsub(/\e\[[0-9]+m/, "")
      end
    end

    class Plot
      include StyledPrinter

      DEFAULT_WIDTH = 40
      DEFAULT_BORDER = :solid
      DEFAULT_MARGIN = 3
      DEFAULT_PADDING = 1

      def initialize(title: nil,
                     xlabel: nil,
                     ylabel: nil,
                     border: DEFAULT_BORDER,
                     margin: DEFAULT_MARGIN,
                     padding: DEFAULT_PADDING,
                     labels: true)
        @title = title
        @xlabel = xlabel
        @ylabel = ylabel
        @border = border
        @margin = check_margin(margin)
        @padding = padding
        @labels_left = {}
        @colors_left = {}
        @labels_right = {}
        @colors_right = {}
        @decorations = {}
        @colors_deco = {}
        @show_labels = labels
        @auto_color = 0
      end

      attr_reader :title
      attr_reader :xlabel
      attr_reader :ylabel
      attr_reader :border
      attr_reader :margin
      attr_reader :padding
      attr_reader :labels_left
      attr_reader :colors_left
      attr_reader :labels_right
      attr_reader :colors_right
      attr_reader :decorations
      attr_reader :colors_deco

      def title_given?
        title && title != ""
      end

      def xlabel_given?
        xlabel && xlabel != ""
      end

      def ylabel_given?
        ylabel && ylabel != ""
      end

      def ylabel_length
        (ylabel && ylabel.length) || 0
      end

      def show_labels?
        @show_labels
      end

      def annotate!(loc, value, color: :normal)
        case loc
        when :l
          (0 ... n_rows).each do |row|
            if @labels_left.fetch(row, "") == ""
              @labels_left[row] = value
              @colors_left[row] = color
              break
            end
          end
        when :r
          (0 ... n_rows).each do |row|
            if @labels_right.fetch(row, "") == ""
              @labels_right[row] = value
              @colors_right[row] = color
              break
            end
          end
        when :t, :b, :tl, :tr, :bl, :br
          @decorations[loc] = value
          @colors_deco[loc] = color
        else
          raise ArgumentError,
            "unknown location to annotate (#{loc.inspect} for :t, :b, :l, :r, :tl, :tr, :bl, or :br)"
        end
      end

      def annotate_row!(loc, row_index, value, color: :normal)
        case loc
        when :l
          @labels_left[row_index] = value
          @colors_left[row_index] = color
        when :r
          @labels_right[row_index] = value
          @colors_right[row_index] = color
        else
          raise ArgumentError, "unknown location `#{loc}`, try :l or :r instead"
        end
      end

      def render(out)
        Renderer.render(out, self)
      end

      COLOR_CYCLE = [
        :green,
        :blue,
        :red,
        :magenta,
        :yellow,
        :cyan
      ].freeze

      def next_color
        COLOR_CYCLE[@auto_color]
      ensure
        @auto_color = (@auto_color + 1) % COLOR_CYCLE.length
      end

      def to_s
        StringIO.open do |sio|
          render(sio)
          sio.close
          sio.string
        end
      end

      private def check_margin(margin)
        if margin < 0
          raise ArgumentError, "margin must be >= 0"
        end
        margin
      end

      private def check_row_index(row_index)
        unless 0 <= row_index && row_index < n_rows
          raise ArgumentError, "row_index out of bounds"
        end
      end
    end

    class Barplot < Plot
      include ValueTransformer

      MIN_WIDTH = 10
      DEFAULT_COLOR = :green
      DEFAULT_SYMBOL = "■"

      def initialize(bars, width, color, symbol, transform, **kw)
        if symbol.length > 1
          raise ArgumentError, "symbol must be a single character"
        end
        @bars = bars
        @symbol = symbol
        @max_freq, i = find_max(transform_values(transform, bars))
        @max_len = bars[i].to_s.length
        @width = [width, max_len + 7, MIN_WIDTH].max
        @color = color
        @symbol = symbol
        @transform = transform
        super(**kw)
      end

      attr_reader :max_freq
      attr_reader :max_len
      attr_reader :width

      def n_rows
        @bars.length
      end

      def n_columns
        @width
      end

      def add_row!(bars)
        @bars.concat(bars)
        @max_freq, i = find_max(transform_values(@transform, bars))
        @max_len = @bars[i].to_s.length
      end

      def print_row(out, row_index)
        check_row_index(row_index)
        bar = @bars[row_index]
        max_bar_width = [width - 2 - max_len, 1].max
        val = transform_values(@transform, bar)
        bar_len = max_freq > 0 ?
          ([val, 0].max.fdiv(max_freq) * max_bar_width).round :
          0
        bar_str = max_freq > 0 ? @symbol * bar_len : ""
        bar_lbl = bar.to_s
        print_styled(out, bar_str, color: @color)
        print_styled(out, " ", bar_lbl, color: :normal)
        pan_len = [max_bar_width + 1 + max_len - bar_len - bar_lbl.length, 0].max
        pad = " " * pan_len.round
        out.print(pad)
      end

      private def find_max(values)
        i = j = 0
        max = values[i]
        while j < values.length
          if values[j] > max
            i, max = j, values[j]
          end
          j += 1
        end
        [max, i]
      end
    end
  end
  private_constant :MiniUnicodePlot
end

