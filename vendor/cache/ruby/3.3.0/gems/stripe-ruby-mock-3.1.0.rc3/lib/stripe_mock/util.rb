module StripeMock
  module Util

    def self.rmerge(desh_hash, source_hash)
      return source_hash if desh_hash.nil?
      return nil if source_hash.nil?

      desh_hash.merge(source_hash) do |key, oldval, newval|
        if oldval.is_a?(Array) && newval.is_a?(Array)
          oldval.fill(nil, oldval.length...newval.length)
          oldval.zip(newval).map {|elems|
            if elems[1].nil?
              elems[0]
            elsif elems[1].is_a?(Hash) && elems[1].is_a?(Hash)
              rmerge(elems[0], elems[1])
            else
              [elems[0], elems[1]].compact
            end
          }.flatten
        elsif oldval.is_a?(Hash) && newval.is_a?(Hash)
          rmerge(oldval, newval)
        else
          newval
        end
      end
    end

    def self.fingerprint(source)
      Digest::SHA1.base64digest(source).gsub(/[^a-z]/i, '')[0..15]
    end

    def self.card_merge(old_param, new_param)
      if new_param[:number] ||= old_param[:number]
        if new_param[:last4]
          new_param[:number] = new_param[:number][0..-5] + new_param[:last4]
        else
          new_param[:last4] = new_param[:number][-4..-1]
        end
      end
      old_param.merge(new_param)
    end

  end
end
