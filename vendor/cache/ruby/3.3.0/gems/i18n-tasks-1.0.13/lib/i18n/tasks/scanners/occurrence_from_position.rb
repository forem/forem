# frozen_string_literal: true

module I18n
  module Tasks
    module Scanners
      module OccurrenceFromPosition
        # Given a path to a file, its contents and a position in the file,
        # return a {Results::Occurrence} at the position until the end of the line.
        #
        # @param path [String]
        # @param contents [String] contents of the file at the path.
        # @param position [Integer] position just before the beginning of the match.
        # @return [Results::Occurrence]
        def occurrence_from_position(path, contents, position, raw_key: nil)
          line_begin = contents.rindex(/^/, position - 1)
          line_end   = contents.index(/.(?=\r?\n|$)/, position)
          Results::Occurrence.new(
            path: path,
            pos: position,
            line_num: contents[0..position].count("\n") + 1,
            line_pos: position - line_begin + 1,
            line: contents[line_begin..line_end],
            raw_key: raw_key
          )
        end
      end
    end
  end
end
