# frozen_string_literal: true

Capybara.add_selector(:table_row, locator_type: [Array, Hash]) do
  xpath do |locator|
    xpath = XPath.descendant(:tr)
    if locator.is_a? Hash
      locator.reduce(xpath) do |xp, (header, cell)|
        header_xp = XPath.ancestor(:table)[1].descendant(:tr)[1].descendant(:th)[XPath.string.n.is(header)]
        cell_xp = XPath.descendant(:td)[
          XPath.string.n.is(cell) & XPath.position.equals(header_xp.preceding_sibling.count.plus(1))
        ]
        xp.where(cell_xp)
      end
    else
      initial_td = XPath.descendant(:td)[XPath.string.n.is(locator.shift)]
      tds = locator.reverse.map { |cell| XPath.following_sibling(:td)[XPath.string.n.is(cell)] }
                   .reduce { |xp, cell| xp.where(cell) }
      xpath[initial_td[tds]]
    end
  end
end
