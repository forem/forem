module Fog
  module AWS
    class CloudWatch
      class AlarmHistory < Fog::Model
        attribute :alarm_name, :aliases => 'AlarmName'
        attribute :end_date, :aliases => 'EndDate'
        attribute :history_item_type, :aliases => 'HistoryItemType'
        attribute :max_records, :aliases => 'MaxRecords'
        attribute :start_date, :aliases => 'StartDate'
      end
    end
  end
end
