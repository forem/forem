# frozen_string_literal: true

module Nokogiri
  module XML
    # :nodoc: all
    module PP
      module Node
        COLLECTIONS = [:attribute_nodes, :children]

        def inspect
          attributes = inspect_attributes.reject do |x|
            attribute = send(x)
            !attribute || (attribute.respond_to?(:empty?) && attribute.empty?)
          rescue NoMethodError
            true
          end
          attributes = if inspect_attributes.length == 1
            send(attributes.first).inspect
          else
            attributes.map do |attribute|
              "#{attribute}=#{send(attribute).inspect}"
            end.join(" ")
          end
          "#<#{self.class.name}:#{format("0x%x", object_id)} #{attributes}>"
        end

        def pretty_print(pp)
          nice_name = self.class.name.split("::").last
          pp.group(2, "#(#{nice_name}:#{format("0x%x", object_id)} {", "})") do
            pp.breakable

            attrs = inspect_attributes.filter_map do |t|
              [t, send(t)] if respond_to?(t)
            end.find_all do |x|
              if x.last
                if COLLECTIONS.include?(x.first)
                  !x.last.empty?
                else
                  true
                end
              end
            end

            if inspect_attributes.length == 1
              pp.pp(attrs.first.last)
            else
              pp.seplist(attrs) do |v|
                if COLLECTIONS.include?(v.first)
                  pp.group(2, "#{v.first} = [", "]") do
                    pp.breakable
                    pp.seplist(v.last) do |item|
                      pp.pp(item)
                    end
                  end
                else
                  pp.text("#{v.first} = ")
                  pp.pp(v.last)
                end
              end
            end

            pp.breakable
          end
        end
      end
    end
  end
end
