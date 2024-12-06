module Fog
  module AWS
    class RDS
      class Parameter < Fog::Model
        attribute  :name, :aliases => ['ParameterName']
        attribute  :data_type, :aliases => 'DataType'
        attribute  :description, :aliases => 'Description'
        attribute  :allowed_values, :aliases => 'AllowedValues'
        attribute  :source, :aliases => 'Source'
        attribute  :modifiable, :aliases => 'IsModifiable'
        attribute  :apply_type, :aliases => 'ApplyType'
        attribute  :value, :aliases => 'ParameterValue'
      end
    end
  end
end
