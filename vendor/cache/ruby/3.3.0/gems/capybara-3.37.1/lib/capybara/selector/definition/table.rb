# frozen_string_literal: true

Capybara.add_selector(:table, locator_type: [String, Symbol]) do
  xpath do |locator, caption: nil, **|
    xpath = XPath.descendant(:table)
    unless locator.nil?
      locator_matchers = (XPath.attr(:id) == locator.to_s) | XPath.descendant(:caption).is(locator.to_s)
      locator_matchers |= XPath.attr(test_id) == locator if test_id
      xpath = xpath[locator_matchers]
    end
    xpath = xpath[XPath.descendant(:caption) == caption] if caption
    xpath
  end

  expression_filter(:with_cols, valid_values: [Array]) do |xpath, cols|
    col_conditions = cols.map do |col|
      if col.is_a? Hash
        col.reduce(nil) do |xp, (header, cell_str)|
          header = XPath.descendant(:th)[XPath.string.n.is(header)]
          td = XPath.descendant(:tr)[header].descendant(:td)
          cell_condition = XPath.string.n.is(cell_str)
          if xp
            prev_cell = XPath.ancestor(:table)[1].join(xp)
            cell_condition &= (prev_cell & prev_col_position?(prev_cell))
          end
          td[cell_condition]
        end
      else
        cells_xp = col.reduce(nil) do |prev_cell, cell_str|
          cell_condition = XPath.string.n.is(cell_str)

          if prev_cell
            prev_cell = XPath.ancestor(:tr)[1].preceding_sibling(:tr).join(prev_cell)
            cell_condition &= (prev_cell & prev_col_position?(prev_cell))
          end

          XPath.descendant(:td)[cell_condition]
        end
        XPath.descendant(:tr).join(cells_xp)
      end
    end.reduce(:&)
    xpath[col_conditions]
  end

  expression_filter(:cols, valid_values: [Array]) do |xpath, cols|
    raise ArgumentError, ':cols must be an Array of Arrays' unless cols.all?(Array)

    rows = cols.transpose
    col_conditions = rows.map { |row| match_row(row, match_size: true) }.reduce(:&)
    xpath[match_row_count(rows.size)][col_conditions]
  end

  expression_filter(:with_rows, valid_values: [Array]) do |xpath, rows|
    rows_conditions = rows.map { |row| match_row(row) }.reduce(:&)
    xpath[rows_conditions]
  end

  expression_filter(:rows, valid_values: [Array]) do |xpath, rows|
    rows_conditions = rows.map { |row| match_row(row, match_size: true) }.reduce(:&)
    xpath[match_row_count(rows.size)][rows_conditions]
  end

  describe_expression_filters do |caption: nil, **|
    " with caption \"#{caption}\"" if caption
  end

  def prev_col_position?(cell)
    XPath.position.equals(cell_position(cell))
  end

  def cell_position(cell)
    cell.preceding_sibling(:td).count.plus(1)
  end

  def match_row(row, match_size: false)
    xp = XPath.descendant(:tr)[
      if row.is_a? Hash
        row_match_cells_to_headers(row)
      else
        XPath.descendant(:td)[row_match_ordered_cells(row)]
      end
    ]
    xp = xp[XPath.descendant(:td).count.equals(row.size)] if match_size
    xp
  end

  def match_row_count(size)
    XPath.descendant(:tbody).descendant(:tr).count.equals(size) |
      (XPath.descendant(:tr).count.equals(size) & ~XPath.descendant(:tbody))
  end

  def row_match_cells_to_headers(row)
    row.map do |header, cell|
      header_xp = XPath.ancestor(:table)[1].descendant(:tr)[1].descendant(:th)[XPath.string.n.is(header)]
      XPath.descendant(:td)[
        XPath.string.n.is(cell) & XPath.position.equals(header_xp.preceding_sibling.count.plus(1))
      ]
    end.reduce(:&)
  end

  def row_match_ordered_cells(row)
    row_conditions = row.map do |cell|
      XPath.self(:td)[XPath.string.n.is(cell)]
    end
    row_conditions.reverse.reduce do |cond, cell|
      cell[XPath.following_sibling[cond]]
    end
  end
end
