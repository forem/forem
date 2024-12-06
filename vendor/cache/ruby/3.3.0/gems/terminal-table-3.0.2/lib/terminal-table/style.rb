# coding: utf-8
require 'forwardable'

module Terminal
  class Table

    class Border

      attr_accessor :data, :top, :bottom, :left, :right
      def initialize
        @top, @bottom, @left, @right = true, true, true, true
      end
      def []=(key, val)
        @data[key] = val
      end
      def [](key)
        @data[key]
      end
      def initialize_dup(other)
        super
        @data = other.data.dup
      end
      def remove_verticals 
        self.class.const_get("VERTICALS").each { |key| @data[key] = "" }
        self.class.const_get("INTERSECTIONS").each { |key| @data[key] = "" }
      end
      def remove_horizontals 
        self.class.const_get("HORIZONTALS").each { |key| @data[key] = "" }
      end
      
      # If @left, return the edge else empty-string.
      def maybeleft(key) ; @left ? @data[key] : '' ; end
      
      # If @right, return the edge else empty-string.
      def mayberight(key) ; @right ? @data[key] : '' ; end

    end
    
    class AsciiBorder < Border
      HORIZONTALS = %i[x]
      VERTICALS = %i[y]
      INTERSECTIONS = %i[i]
      
      def initialize
        super
        @data = { x: "-", y: "|", i:  "+" }
      end
      
      # Get vertical border elements
      # @return [Array] 3-element list of [left, center, right]
      def vertical
        [maybeleft(:y), @data[:y], mayberight(:y)] # left, center, right
      end
      
      # Get horizontal border elements
      # @return [Array] a 6 element list of: [i-left, horizontal-bar, i-up/down, i-right, i-down, i-up]
      def horizontal(_type)
        x, i = @data[:x], @data[:i]
        [maybeleft(:i), x, i, mayberight(:i), i, i]
      end
    end

    class MarkdownBorder < AsciiBorder
      def initialize
        super
        @top, @bottom = false, false
        @data = { x: "-", y: "|", i:  "|" }
      end
    end
    
    class UnicodeBorder < Border

      ALLOWED_SEPARATOR_BORDER_STYLES = %i[
      top bot 
      div dash dot3 dot4 
      thick thick_dash thick_dot3 thick_dot4
      heavy heavy_dash heavy_dot3 heavy_dot4
      bold bold_dash bold_dot3 bold_dot4
      double
      ]  

      HORIZONTALS = %i[x sx ax bx nx bx_dot3 bx_dot4 bx_dash x_dot3 x_dot4 x_dash]
      VERTICALS = %i[y yw ye]
      INTERSECTIONS = %i[nw n ne nd 
                         aw ai ae ad au
                         bw bi be bd bu
                         w i e dn up 
                         sw s se su]
      def initialize
        super
        @data = {
          nil => nil,
          nw: "┌", nx: "─", n:  "┬", ne: "┐",
          yw: "│",          y:  "│", ye: "│", 
          aw: "╞", ax: "═", ai: "╪", ae: "╡", ad: '╤', au: "╧", # double
          bw: "┝", bx: "━", bi: "┿", be: "┥", bd: '┯', bu: "┷", # heavy/bold/thick
          w:  "├", x:  "─", i:  "┼", e:  "┤", dn: "┬", up: "┴", # normal div
          sw: "└", sx: "─", s:  "┴", se: "┘",
          # alternative dots/dashes
          x_dot4:  '┈', x_dot3:  '┄', x_dash:  '╌',
          bx_dot4: '┉', bx_dot3: '┅', bx_dash: '╍',
        }
      end
      # Get vertical border elements
      # @return [Array] 3-element list of [left, center, right]
      def vertical
        [maybeleft(:yw), @data[:y], mayberight(:ye)] 
      end

      # Get horizontal border elements
      # @return [Array] a 6 element list of: [i-left, horizontal-bar, i-up/down, i-right, i-down, i-up]
      def horizontal(type)
        raise ArgumentError, "Border type is #{type.inspect}, must be one of #{ALLOWED_SEPARATOR_BORDER_STYLES.inspect}" unless ALLOWED_SEPARATOR_BORDER_STYLES.include?(type)
        lookup = case type
                 when :top
                   [:nw, :nx, :n, :ne, :n, nil]
                 when :bot
                   [:sw, :sx, :s, :se, nil, :s]
                 when :double
                   # typically used for the separator below the heading row or above a footer row)
                   [:aw, :ax, :ai, :ae, :ad, :au]
                 when :thick, :thick_dash, :thick_dot3, :thick_dot4,
                      :heavy, :heavy_dash, :heavy_dot3, :heavy_dot4,
                      :bold, :bold_dash, :bold_dot3, :bold_dot4
                   # alternate thick/bold border
                   xref = type.to_s.sub(/^(thick|heavy|bold)/,'bx').to_sym
                   [:bw, xref, :bi, :be, :bd, :bu]
                 when :dash, :dot3, :dot4
                   # alternate thin dividers
                   xref = "x_#{type}".to_sym
                   [:w, xref, :i, :e, :dn, :up]
                 else  # :div (center, non-emphasized)
                   [:w, :x, :i, :e, :dn, :up]
                 end
        rval = lookup.map { |key| @data.fetch(key) }
        rval[0] = '' unless @left
        rval[3] = '' unless @right
        rval
      end
    end

    # Unicode Border With rounded edges
    class UnicodeRoundBorder < UnicodeBorder
      def initialize
        super
        @data.merge!({nw: '╭', ne: '╮', sw: '╰', se: '╯'})
      end
    end

    # Unicode Border with thick outer edges
    class UnicodeThickEdgeBorder < UnicodeBorder
      def initialize
        super
        @data = {
          nil => nil,
          nw: "┏", nx: "━", n:  "┯", ne: "┓", nd: nil,
          yw: "┃",          y:  "│", ye: "┃", 
          aw: "┣", ax: "═", ai: "╪", ae: "┫", ad: '╤', au: "╧", # double
          bw: "┣", bx: "━", bi: "┿", be: "┫", bd: '┯', bu: "┷", # heavy/bold/thick
          w:  "┠", x:  "─", i:  "┼", e:  "┨", dn: "┬", up: "┴", # normal div
          sw: "┗", sx: "━", s:  "┷", se: "┛", su:  nil,
          # alternative dots/dashes
          x_dot4:  '┈', x_dot3:  '┄', x_dash:  '╌',
          bx_dot4: '┉', bx_dot3: '┅', bx_dash: '╍',
        }
      end
    end
    
    # A Style object holds all the formatting information for a Table object
    #
    # To create a table with a certain style, use either the constructor
    # option <tt>:style</tt>, the Table#style object or the Table#style= method
    #
    # All these examples have the same effect:
    #
    #     # by constructor
    #     @table = Table.new(:style => {:padding_left => 2, :width => 40})
    #
    #     # by object
    #     @table.style.padding_left = 2
    #     @table.style.width = 40
    #
    #     # by method
    #     @table.style = {:padding_left => 2, :width => 40}
    #
    # To set a default style for all tables created afterwards use Style.defaults=
    #
    #     Terminal::Table::Style.defaults = {:width => 80}
    #
    class Style
      extend Forwardable
      def_delegators :@border, :vertical, :horizontal, :remove_verticals, :remove_horizontals
      
      @@defaults = {
        :border => AsciiBorder.new,
        :padding_left => 1, :padding_right => 1,
        :margin_left => '',
        :width => nil, :alignment => nil,
        :all_separators => false,
      }

      ## settors/gettor for legacy ascii borders
      def border_x=(val) ; @border[:x] = val ; end
      def border_y=(val) ; @border[:y] = val ; end
      def border_i=(val) ; @border[:i] = val ; end
      def border_y ; @border[:y] ; end
      def border_y_width ; Util::ansi_escape(@border[:y]).length ; end

      # Accessor for instance of Border
      attr_reader :border
      def border=(val)
        if val.is_a? Symbol
          # convert symbol name like :foo_bar to get class FooBarBorder
          klass_str = val.to_s.split('_').collect(&:capitalize).join + "Border"
          begin
            klass = Terminal::Table::const_get(klass_str)
            @border = klass.new
          rescue NameError
            raise "Cannot lookup class Terminal::Table::#{klass_str} from symbol #{val.inspect}"
          end
        else
          @border = val
        end
      end

      def border_top=(val) ; @border.top = val ; end
      def border_bottom=(val) ; @border.bottom = val ; end
      def border_left=(val) ; @border.left = val ; end
      def border_right=(val) ; @border.right = val ; end

      def border_top ; @border.top ; end
      def border_bottom ; @border.bottom ; end
      def border_left ; @border.left ; end
      def border_right ; @border.right ; end


      attr_accessor :padding_left
      attr_accessor :padding_right

      attr_accessor :margin_left

      attr_accessor :width
      attr_accessor :alignment

      attr_accessor :all_separators

      
      def initialize options = {}
        apply self.class.defaults.merge(options)
      end

      def apply options
        options.each do |m, v|
          __send__ "#{m}=", v
        end
      end
      
      class << self
        def defaults
          klass_defaults = @@defaults.dup
          # border is an object that needs to be duplicated on instantiation,
          # otherwise everything will be referencing the same object-id.
          klass_defaults[:border] = klass_defaults[:border].dup
          klass_defaults
        end
        
        def defaults= options
          @@defaults = defaults.merge(options)
        end

      end

      def on_change attr
        method_name = :"#{attr}="
        old_method = method method_name
        define_singleton_method(method_name) do |value|
          old_method.call value
          yield attr.to_sym, value
        end
      end
          
    end
  end
end
