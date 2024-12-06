# frozen_string_literal: true

require 'jaro_winkler/adjusting_table'
module JaroWinkler
  class Error < RuntimeError; end
  class InvalidWeightError < Error; end

  DEFAULT_WEIGHT = 0.1
  DEFAULT_THRESHOLD = 0.7
  DEFAULT_OPTIONS = {
    jaro: { adj_table: false, ignore_case: false },
    jaro_winkler: { weight: DEFAULT_WEIGHT, threshold: DEFAULT_THRESHOLD }
  }.freeze

  class << self
    def distance(str1, str2, options = {})
      validate!(str1, str2)
      _distance str1.codepoints.to_a, str2.codepoints.to_a, options
    end

    def jaro_distance(str1, str2, options = {})
      validate!(str1, str2)
      _jaro_distance str1.codepoints.to_a, str2.codepoints.to_a, options
    end

    private

    def _distance(codes1, codes2, options = {})
      options = DEFAULT_OPTIONS[:jaro_winkler].merge options
      raise InvalidWeightError if options[:weight] > 0.25
      jaro_distance = _jaro_distance(codes1, codes2, options)

      if jaro_distance < options[:threshold]
        jaro_distance
      else
        codes1, codes2 = codes2, codes1 if codes1.length > codes2.length
        len1 = codes1.length
        len2 = codes2.length
        max_4 = len1 > 4 ? 4 : len1
        prefix = 0
        prefix += 1 while prefix < max_4 && codes1[prefix] == codes2[prefix]
        jaro_distance + prefix * options[:weight] * (1 - jaro_distance)
      end
    end

    def _jaro_distance(codes1, codes2, options = {})
      options = DEFAULT_OPTIONS[:jaro].merge options

      codes1, codes2 = codes2, codes1 if codes1.length > codes2.length
      len1 = codes1.length
      len2 = codes2.length
      return 0.0 if len1 == 0 || len2 == 0

      if options[:ignore_case]
        codes1.map! { |c| c >= 97 && c <= 122 ? c -= 32 : c }
        codes2.map! { |c| c >= 97 && c <= 122 ? c -= 32 : c }
      end

      window = len2 / 2 - 1
      window = 0 if window < 0
      flags1 = 0
      flags2 = 0

      # // count number of matching characters
      match_count = 0
      i = 0
      while i < len1
        left = i >= window ? i - window : 0
        right = i + window <= len2 - 1 ? (i + window) : (len2 - 1)
        right = len2 - 1 if right > len2 - 1
        j = left
        while j <= right
          if flags2[j] == 0 && codes1[i] == codes2[j]
            flags1 |= (1 << i)
            flags2 |= (1 << j)
            match_count += 1
            break
          end
          j += 1
        end
        i += 1
      end

      return 0.0 if match_count == 0

      # // count number of transpositions
      transposition_count = j = k = 0
      i = 0
      while i < len1
        if flags1[i] == 1
          j = k
          while j < len2
            if flags2[j] == 1
              k = j + 1
              break
            end
            j += 1
          end
          transposition_count += 1 if codes1[i] != codes2[j]
        end
        i += 1
      end

      # // count similarities in nonmatched characters
      similar_count = 0
      if options[:adj_table] && len1 > match_count
        i = 0
        while i < len1
          if flags1[i] == 0
            j = 0
            while j < len2
              if flags2[j] == 0
                if DEFAULT_ADJ_TABLE[codes1[i].chr(Encoding::UTF_8)][codes2[j].chr(Encoding::UTF_8)]
                  similar_count += 3
                  break
                end
              end
              j += 1
            end
          end
          i += 1
        end
      end

      m = match_count.to_f
      t = transposition_count / 2
      m = similar_count / 10.0 + m if options[:adj_table]
      (m / len1 + m / len2 + (m - t) / m) / 3
    end

    def validate!(str1, str2)
      raise TypeError unless str1.is_a?(String) && str2.is_a?(String)
    end
  end
end
