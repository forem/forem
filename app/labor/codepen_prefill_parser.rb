module CodepenPrefillParser
  def check_codepenprefill(html)
    check_start = (html =~ /codepenprefill/)
    check_end = (html =~ /endcodepenprefill/)
    html = get_codepen_chunks(html) if check_start && check_end && (check_end > check_start)
    html
  end

  def get_codepen_chunks(html)
    # look for start positions of codepen prefills
    # look for end positions of codepen prefills
    start_pos = html.gsub(/(\{\% codepenprefill )/).map { Regexp.last_match.begin(0) }
    end_pos = html.gsub(/\{\% endcodepenprefill %\}\.{0}/).map { Regexp.last_match.begin(0) + 23 }
    raise "Some Codepen Prefill Liquid Tags are not closed properly" if start_pos.length != end_pos.length

    (0..(start_pos.length - 1)).each do |i|
      save_codepen_html(html, start_pos[i], end_pos[i])
    end
    html
  end

  def save_codepen_html(html, start_pos, end_pos)
    start_html = html[start_pos, (end_pos - start_pos)].gsub(/<pre.*data-lang=('|"){1}html('|"){1}.*>/).map { Regexp.last_match.begin(0) + html[start_pos, (end_pos - start_pos)][/<pre data-lang=('|"){1}html('|"){1}[^\/\<]*>/].size }
    end_html = html[start_pos, (end_pos - start_pos)].gsub(/<\/\ {0}pre>/).map { Regexp.last_match.begin(0) }

    if start_html.is_a?(Integer) && end_html.is_a?(Integer)
      start_html = [start_html]
      end_html = [end_html]
    end

    (0..(start_html.length - 1)).each do |j|
      html[(start_pos + start_html[j]), (end_html[j] - start_html[j])] = html[(start_pos + start_html[j]), (end_html[j] - start_html[j])].gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end
  end
end
