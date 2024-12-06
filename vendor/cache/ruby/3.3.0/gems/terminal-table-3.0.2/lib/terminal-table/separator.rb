module Terminal
  class Table
    class Separator < Row

      ##
      # `prevrow`, `nextrow` contain references to adjacent rows.
      #
      # `border_type` is a symbol used to control which type of border is used
      # on the separator (:top for top-edge, :bot for bottom-edge,
      # :div for interior, and :strong for emphasized-interior)
      #
      # `implicit` is false for user-added separators, and true for
      # implicit/auto-generated separators.
      
      def initialize(*args, border_type: :div, implicit: false)
        super
        @prevrow, @nextrow = nil, nil
        @border_type = border_type
        @implicit = implicit
      end

      attr_accessor :border_type
      attr_reader :implicit
      
      def render
        left_edge, ctrflat, ctrud, right_edge, ctrdn, ctrup = @table.style.horizontal(border_type)
        
        prev_crossings = @prevrow.respond_to?(:crossings) ? @prevrow.crossings : []
        next_crossings = @nextrow.respond_to?(:crossings) ? @nextrow.crossings : []
        rval = [left_edge]
        numcols = @table.number_of_columns
        (0...numcols).each do |idx|
          rval << ctrflat * (@table.column_width(idx) + @table.cell_padding)
          pcinc = prev_crossings.include?(idx+1)
          ncinc = next_crossings.include?(idx+1)
          border_center = if pcinc && ncinc
                            ctrud
                          elsif pcinc
                            ctrup
                          elsif ncinc
                            ctrdn
                          elsif !ctrud.empty?
                            # special case if the center-up-down intersection is empty
                            # which happens when verticals/intersections are removed. in that case
                            # we do not want to replace with a flat element so return empty-string in else block
                            ctrflat
                          else
                            ''
                          end
          rval << border_center if idx < numcols-1
        end
          
        rval << right_edge
        rval.join
      end

      # Save off neighboring rows, so that we can use them later in determining
      # which types of table edges to use.
      def save_adjacent_rows(prevrow, nextrow)
        @prevrow = prevrow
        @nextrow = nextrow
      end
      
    end
  end
end
