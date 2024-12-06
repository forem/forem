module CarrierWave
  module Compatibility

    ##
    # Mix this module into an Uploader to make it mimic Paperclip's storage paths
    # This will make your Uploader use the same default storage path as paperclip
    # does. If you need to override it, you can override the +paperclip_path+ method
    # and provide a Paperclip style path:
    #
    #     class MyUploader < CarrierWave::Uploader::Base
    #       include CarrierWave::Compatibility::Paperclip
    #
    #       def paperclip_path
    #         ":rails_root/public/uploads/:id/:attachment/:style_:basename.:extension"
    #       end
    #     end
    #
    # ---
    #
    # This file contains code taken from Paperclip
    #
    # LICENSE
    #
    # The MIT License
    #
    # Copyright (c) 2008 Jon Yurek and thoughtbot, inc.
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in
    # all copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    # THE SOFTWARE.
    #
    module Paperclip
      extend ActiveSupport::Concern

      DEFAULT_MAPPINGS = {
        :rails_root   => lambda{|u, f| Rails.root.to_s },
        :rails_env    => lambda{|u, f| Rails.env },
        :id_partition => lambda{|u, f| ("%09d" % u.model.id).scan(/\d{3}/).join("/")},
        :id           => lambda{|u, f| u.model.id },
        :attachment   => lambda{|u, f| u.mounted_as.to_s.downcase.pluralize },
        :style        => lambda{|u, f| u.paperclip_style },
        :basename     => lambda{|u, f| u.filename.gsub(/#{File.extname(u.filename)}$/, "") },
        :extension    => lambda{|u, d| File.extname(u.filename).gsub(/^\.+/, "")},
        :class        => lambda{|u, f| u.model.class.name.underscore.pluralize}
      }

      included do
        attr_accessor :filename
        class_attribute :mappings
        self.mappings ||= DEFAULT_MAPPINGS.dup
      end

      def store_path(for_file=filename)
        path = paperclip_path
        self.filename = for_file
        path ||= File.join(*[store_dir, paperclip_style.to_s, for_file].compact)
        interpolate_paperclip_path(path)
      end

      def store_dir
        ":rails_root/public/system/:attachment/:id"
      end

      def paperclip_default_style
        :original
      end

      def paperclip_path
      end

      def paperclip_style
        version_name || paperclip_default_style
      end

      module ClassMethods
        def interpolate(sym, &block)
          mappings[sym] = block
        end
      end

      private
      def interpolate_paperclip_path(path)
        mappings.each_pair.inject(path) do |agg, pair|
          agg.gsub(":#{pair[0]}") { pair[1].call(self, self.paperclip_style).to_s }
        end
      end
    end # Paperclip
  end # Compatibility
end # CarrierWave
