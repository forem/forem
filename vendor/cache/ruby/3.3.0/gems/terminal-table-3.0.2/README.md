[![CI status](https://github.com/tj/terminal-table/workflows/CI/badge.svg)](https://github.com/tj/terminal-table/actions)
[![Gem Version](https://badge.fury.io/rb/terminal-table.svg)](https://badge.fury.io/rb/terminal-table)

# Terminal Table

## Description

Terminal Table is a fast and simple, yet feature rich table generator
written in Ruby.  It supports ASCII and Unicode formatted tables.

## Installation

```
$ gem install terminal-table
```
## Usage

### Basics

To use Terminal Table:

```ruby
require 'terminal-table'
```
To generate a table, provide an array of arrays (which are interpreted as
rows):

```ruby
rows = []
rows << ['One', 1]
rows << ['Two', 2]
rows << ['Three', 3]
table = Terminal::Table.new :rows => rows

# > puts table
#
# +-------+---+
# | One   | 1 |
# | Two   | 2 |
# | Three | 3 |
# +-------+---+
```
The constructor can also be given a block which is either yielded the Table
object or instance evaluated:

```ruby
table = Terminal::Table.new do |t|
  t.rows = rows
end

table = Terminal::Table.new do
  self.rows = rows
end
```
Adding rows one by one:

```ruby
table = Terminal::Table.new do |t|
  t << ['One', 1]
  t.add_row ['Two', 2]
end
```
To add separators between rows:

```ruby
table = Terminal::Table.new do |t|
  t << ['One', 1]          # Using << (push) as an alias for add_row
  t << :separator          # Using << with :separator as an alias for add_separator
  t.add_row ['Two', 2]
  t.add_separator          # Note - this version allows setting the separator's border_type
  t.add_row ['Three', 3]
end

# > puts table
#
# +-------+---+
# | One   | 1 |
# +-------+---+
# | Two   | 2 |
# +-------+---+
# | Three | 3 |
# +-------+---+
```
Cells can handle multiline content:

```ruby
table = Terminal::Table.new do |t|
  t << ['One', 1]
  t << :separator
  t.add_row ["Two\nDouble", 2]
  t.add_separator
  t.add_row ['Three', 3]
end

# > puts table
#
# +--------+---+
# | One    | 1 |
# +--------+---+
# | Two    | 2 |
# | Double |   |
# +--------+---+
# | Three  | 3 |
# +--------+---+
```
### Head

To add a head to the table:

```ruby
table = Terminal::Table.new :headings => ['Word', 'Number'], :rows => rows

# > puts table
#
# +-------+--------+
# | Word  | Number |
# +-------+--------+
# | One   | 1      |
# | Two   | 2      |
# | Three | 3      |
# +-------+--------+
```
### Title

To add a title to the table:

```ruby
table = Terminal::Table.new :title => "Cheatsheet", :headings => ['Word', 'Number'], :rows => rows

# > puts table
#
# +---------------------+
# |     Cheatsheet      |
# +------------+--------+
# | Word       | Number |
# +------------+--------+
# | One        | 1      |
# | Two        | 2      |
# | Three      | 3      |
# +------------+--------+
```
### Alignment

To align the second column to the right:

```ruby
table.align_column(1, :right)

# > puts table
#
# +-------+--------+
# | Word  | Number |
# +-------+--------+
# | One   |      1 |
# | Two   |      2 |
# | Three |      3 |
# +-------+--------+
```
To align an individual cell, you specify the cell value in a hash along the
alignment:

```ruby
table << ["Four", {:value => 4.0, :alignment => :center}]

# > puts table
#
# +-------+--------+
# | Word  | Number |
# +-------+--------+
# | One   |      1 |
# | Two   |      2 |
# | Three |      3 |
# | Four  |  4.0   |
# +-------+--------+
```
### Style

To specify style options:

```ruby
table = Terminal::Table.new :headings => ['Word', 'Number'], :rows => rows, :style => {:width => 80}

# > puts table
#
# +--------------------------------------+---------------------------------------+
# | Word                                 | Number                                |
# +--------------------------------------+---------------------------------------+
# | One                                  | 1                                     |
# | Two                                  | 2                                     |
# | Three                                | 3                                     |
# +--------------------------------------+---------------------------------------+
```
And change styles on the fly:

```ruby
table.style = {:width => 40, :padding_left => 3, :border_x => "=", :border_i => "x"}

# > puts table
#
# x======================================x
# |               Cheatsheet             |
# x====================x=================x
# |   Word             |   Number        |
# x====================x=================x
# |   One              |   1             |
# |   Two              |   2             |
# |   Three            |   3             |
# x====================x=================x
```
You can also use styles to add a separator after every row:

```ruby
table = Terminal::Table.new do |t|
  t.add_row [1, 'One']
  t.add_row [2, 'Two']
  t.add_row [3, 'Three']
  t.style = {:all_separators => true}
end

# > puts table
#
# +---+-------+
# | 1 | One   |
# +---+-------+
# | 2 | Two   |
# +---+-------+
# | 3 | Three |
# +---+-------+
```
You can also use styles to disable top and bottom borders of the table.

```ruby
table = Terminal::Table.new do |t|
  t.headings = ['id', 'name']
  t.rows = [[1, 'One'], [2, 'Two'], [3, 'Three']]
  t.style = { :border_top => false, :border_bottom => false }
end

# > puts table
# | id | name  |
# +----+-------+
# | 1  | One   |
# | 2  | Two   |
# | 3  | Three |
```

And also to disable left and right borders of the table.

```ruby
table = Terminal::Table.new do |t|
  t.headings = ['id', 'name']
  t.rows = [[1, 'One'], [2, 'Two'], [3, 'Three']]
  t.style = { :border_left => false, :border_right => false }
end

# > puts table
# ----+-------
#  id | name
# ----+-------
#  1  | One
#  2  | Two
#  3  | Three
# ----+-------
```

To change the default style options:

```ruby
Terminal::Table::Style.defaults = {:width => 80}
```
All Table objects created afterwards will inherit these defaults.

### Constructor options and setter methods

Valid options for the constructor are `:rows`, `:headings`, `:style` and `:title` -
and all options can also be set on the created table object by their setter
method:

```ruby
table = Terminal::Table.new
table.title = "Cheatsheet"
table.headings = ['Word', 'Number']
table.rows = rows
table.style = {:width => 40}
```

## New Formatting

### Unicode Table Borders
Support for Unicode 'box art' borders presented a challenge, as the original terminal-table only handled three border types:  horizontal (x), vertical (y), and intersection (i).  For proper box-art, it became necessary to enable different types of corners/edges for multiple intersection types.

For the sake of backward compatiblity, the previous interface is still supported, as this gem has been around a long time and making breaking changes would have been inconvenient.  The new interface is required for any complex and/or Unicode style bordering. A few variations on border style are supported via some new classes and creation of additional classes (or modification of characters used in existing ones) will allow for customized border types.

The simplest way to use an alternate border is one of the following:
```
table.style = { :border => :unicode }
table.style = { :border => :unicode_round }
table.style = { :border => :unicode_thick_edge }
```

These are a convenience wrapper around setting border using an instance of a class that inherits from Table::Terminal::Border
```
table.style = { :border => Terminal::Table::UnicodeBorder.new() }
table.style = { :border => Terminal::Table::UnicodeRoundBorder.new() }
table.style = { :border => Terminal::Table::UnicodeThickEdgeBorder.new() }
```

If you define a custom class and wish to use the symbol shortcut, you must namespace within `Terminal::Table` and end your class name with `Border`.

### Markdown Compatiblity
Per popular request, Markdown formatted tables can be generated by using the following border style:

```
table.style = { :border => :markdown }
```

### Ascii Borders
Ascii borders are default, but can be explicitly set with:
```
table.style = { :border => :ascii }
```

### Customizing Borders
Inside the `UnicodeBorder` class, there are definitions for a variety of corner/intersection and divider types.

```ruby
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
```

Note that many are defined as directional (:nw == north-west), others defined in terms of 'x' or 'y'.
The border that separates headings (below each heading) is of type `:double` and is defined with `a*` entries.
Alternate `:heavy` types that can be applied to separators can be defined with `b*` entries.

When defining a new set of borders, it's probably easiest to define a new class that inherits from UnicodeBorder and replaces the `@data` Hash.
However, these elements can be these can be overridden by poking setting the Hash, should the need arise:

```
table.style = {border: :unicode}
table.style.border[:nw] = '*'  # Override the north-west corner of the table
```

### Customizing row separators

Row-separators can now be customized in a variety of ways.  The default separator's border_type is referred to as `:div`.  Additional separator border types (e.g. `:double`, `:heavy`, `:dash` - see full list below) can be applied to separate the sections (e.g. header/footer/title).

The separator's `border_type`  may be specified when a user-defined separator is added.  Alternatively, borders may be adjusted after the table's rows are elaborated, but before the table is rendered.

Separator `border_type`s can be adjusted to be heavy, use double-lines, and different dash/dot styles.  The border type should be one of:

    div dash dot3 dot4 
    thick thick_dash thick_dot3 thick_dot4
    heavy heavy_dash heavy_dot3 heavy_dot4
    bold bold_dash bold_dot3 bold_dot4
    double

To manually set the separator border_type, the `add_separator` method may be called.
```ruby
add_separator(border_type: :heavy_dash)
```

Alternatively, if `style: :all_separators` is used at the table level, it may be necessary to elaborate the implicit Separator rows prior to rendering.
```ruby
table = Terminal::Table.new do |t|
  t.add_row [1, 'One']
  t.add_row [2, 'Two']
  t.add_row [3, 'Three']
  t.style = {:all_separators => true}
end
rows = table.elaborate_rows
rows[2].border_type = :heavy # modify separator row: emphasize below title
puts table.render
```

## Example: Displaying a small CSV spreadsheet

This example code demonstrates using Terminal-table and CSV to display a small spreadsheet.

```ruby
#!/usr/bin/env ruby
require "csv"
require "terminal-table"
use_stdin = ARGV[0].nil? || (ARGV[0] == '-')
io_object = use_stdin ? $stdin : File.open(ARGV[0], 'r')
csv = CSV.new(io_object)
csv_array = csv.to_a
user_table = Terminal::Table.new do |v|
  v.style = { :border => :unicode_round } # >= v3.0.0
  v.title = "Some Title"
  v.headings = csv_array[0]
  v.rows = csv_array[1..-1]
end
puts user_table
```

See also `examples/show_csv_table.rb` in the source distribution.

## More examples

For more examples, please see the `examples` directory included in the
source distribution.

## Author

TJ Holowaychuk <tj@vision-media.ca>

Unicode table support by Ben Bowers https://github.com/nanobowers
