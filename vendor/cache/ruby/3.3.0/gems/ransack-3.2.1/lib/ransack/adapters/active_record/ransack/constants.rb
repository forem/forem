module Ransack
  module Constants
    DISTINCT = 'DISTINCT '.freeze

    DERIVED_PREDICATES = [
      [CONT, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['not_cont'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}%" }
        }
      ],
      ['i_cont'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v.downcase)}%" },
        case_insensitive: true
        }
      ],
      ['not_i_cont'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v.downcase)}%" },
        case_insensitive: true
        }
      ],
      ['start'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['not_start'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "#{escape_wildcards(v)}%" }
        }
      ],
      ['end'.freeze, {
        arel_predicate: 'matches'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['not_end'.freeze, {
        arel_predicate: 'does_not_match'.freeze,
        formatter: proc { |v| "%#{escape_wildcards(v)}" }
        }
      ],
      ['true'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| true }
        }
      ],
      ['not_true'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| true }
        }
      ],
      ['false'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| false }
        }
      ],
      ['not_false'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| false }
        }
      ],
      ['present'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ_ALL : EQ_ANY },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''.freeze].freeze }
        }
      ],
      ['blank'.freeze, {
        arel_predicate: proc { |v| v ? EQ_ANY : NOT_EQ_ALL },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| [nil, ''.freeze].freeze }
        }
      ],
      ['null'.freeze, {
        arel_predicate: proc { |v| v ? EQ : NOT_EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| nil }
        }
      ],
      ['not_null'.freeze, {
        arel_predicate: proc { |v| v ? NOT_EQ : EQ },
        compounds: false,
        type: :boolean,
        validator: proc { |v| BOOLEAN_VALUES.include?(v) },
        formatter: proc { |v| nil } }
      ]
    ].freeze

  module_function
    # replace % \ to \% \\
    def escape_wildcards(unescaped)
      case ActiveRecord::Base.connection.adapter_name
      when "Mysql2".freeze
        # Necessary for MySQL
        unescaped.to_s.gsub(/([\\%_])/, '\\\\\\1')
      when "PostgreSQL".freeze
        # Necessary for PostgreSQL
        unescaped.to_s.gsub(/([\\%_.])/, '\\\\\\1')
      else
        unescaped
      end
    end
  end
end
