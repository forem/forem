# frozen_string_literal: true

module I18n::Tasks
  class ConsoleContext < BaseTask
    def to_s
      @to_s ||= "i18n-tasks-#{I18n::Tasks::VERSION}"
    end

    def banner
      puts Messages.banner
    end

    def guide
      puts Messages.guide
    end

    class << self
      def start
        require 'irb'
        IRB.setup nil
        ctx = IRB::Irb.new.context
        IRB.conf[:MAIN_CONTEXT] = ctx
        $stderr.puts Messages.banner
        require 'irb/ext/multi-irb'
        IRB.irb nil, new
      end
    end

    module Messages
      module_function

      def banner
        Rainbow("i18n-tasks v#{I18n::Tasks::VERSION} IRB").bright + "\nType #{Rainbow('guide').green} to learn more"
      end

      def guide
        "#{Rainbow('i18n-tasks IRB Quick Start guide').green.bright}\n#{<<~TEXT}"
          #{Rainbow('Data as trees').yellow}
            tree(locale)
            used_tree(key_filter: nil, strict: nil)
            unused_tree(locale: base_locale, strict: nil)
            build_tree('es' => {'hello' => 'Hola'})

          #{Rainbow('Traversal').yellow}
            tree = missing_diff_tree('es')
            tree.nodes { |node| }
            tree.nodes.to_a
            tree.leaves { |node| }
            tree.each { |root_node| }
            # also levels, depth_first, and breadth_first

          #{Rainbow('Select nodes').yellow}
            tree.select_nodes { |node| } # new tree with only selected nodes

          #{Rainbow('Match by full key').yellow}
            tree.select_keys { |key, leaf| } # new tree with only selected keys
            tree.grep_keys(/hello/)          # grep, using ===
            tree.keys { |key, leaf| }        # enumerate over [full_key, leaf_node]
            # Pass {root: true} to include root node in full_key (usually locale)

          #{Rainbow('Nodes').yellow}
            node = node(key, locale)
            node.key      # only the part after the last dot
            node.full_key # full key. Includes root key, pass {root: false} to override.
            # also: value, value_or_children_hash, data, walk_to_root, walk_from_root
            Tree::Node.new(key: 'en')

          #{Rainbow('Keys').yellow}
            t(key, locale)
            key_value?(key, locale)
            depluralize_key(key, locale) # convert 'hat.one' to 'hat'
        TEXT
      end
    end
  end
end
