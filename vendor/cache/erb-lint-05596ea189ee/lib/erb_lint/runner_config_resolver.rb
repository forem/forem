# frozen_string_literal: true

# Copyright (c) 2012-18 Bozhidar Batsov
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ERBLint
  class RunnerConfigResolver
    def resolve_inheritance(hash, file_loader)
      inherited_files = Array(hash['inherit_from'])
      base_configs(file_loader, inherited_files).reverse_each do |base_config|
        base_config.each do |k, v|
          next unless v.is_a?(Hash)
          v = v.deep_merge(hash[k]) if hash.key?(k)
          hash[k] = v
        end
      end
    end

    def resolve_inheritance_from_gems(hash, gems)
      (gems || {}).each_pair do |gem_name, config_path|
        raise(ArgumentError, "can't inherit configuration from the erb-lint gem") if gem_name == 'erb-lint'

        hash['inherit_from'] = Array(hash['inherit_from'])
        Array(config_path).reverse_each do |path|
          # Put gem configuration first so local configuration overrides it.
          hash['inherit_from'].unshift(gem_config_path(gem_name, path))
        end
      end
    end

    private

    def gem_config_path(gem_name, relative_config_path)
      spec = Gem::Specification.find_by_name(gem_name)
      File.join(spec.gem_dir, relative_config_path)
    rescue Gem::LoadError => e
      raise Gem::LoadError, "Unable to find gem #{gem_name}; is the gem installed? #{e}"
    end

    def base_configs(file_loader, inherit_from)
      configs = Array(inherit_from).compact.map do |f|
        inherited_file = File.expand_path(f, file_loader.base_path)
        file_loader.yaml(inherited_file)
      end
      configs.compact
    end
  end
end
