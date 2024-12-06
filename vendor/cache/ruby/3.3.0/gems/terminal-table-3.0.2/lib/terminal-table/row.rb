module Terminal
  class Table
    class Row

      ##
      # Row cells

      attr_reader :cells

      attr_reader :table

      ##
      # Initialize with _width_ and _options_.

      def initialize table, array = [], **_kwargs
        @cell_index = 0
        @table = table
        @cells = []
        array.each { |item| self << item }
      end

      def add_cell item
        options = item.is_a?(Hash) ? item : {:value => item}
        cell = Cell.new(options.merge(:index => @cell_index, :table => @table))
        @cell_index += cell.colspan
        @cells << cell
      end
      alias << add_cell

      def [] index
        cells[index]
      end

      def height
        cells.map { |c| c.lines.count }.max || 0
      end

      def render
        vleft, vcenter, vright = @table.style.vertical
        (0...height).to_a.map do |line|
          vleft + cells.map do |cell|
            cell.render(line)
          end.join(vcenter) + vright
        end.join("\n")
      end

      def number_of_columns
        @cells.collect(&:colspan).inject(0, &:+)
      end

      # used to find indices where we have table '+' crossings.
      # in cases where the colspan > 1, then we will skip over some numbers
      # if colspan is always 1, then the list should be incrementing by 1.
      #
      # skip 0 entry, because it's the left side.
      # skip last entry, because it's the right side.
      # we only care about "+/T" style crossings.
      def crossings
        idx = 0
        @cells[0...-1].map { |c| idx += c.colspan } 
      end
      
    end

  end
end
