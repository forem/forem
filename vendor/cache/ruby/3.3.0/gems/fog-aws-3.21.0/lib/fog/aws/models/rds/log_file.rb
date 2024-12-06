module Fog
  module AWS
    class RDS
      class LogFile < Fog::Model
        attribute :rds_id, :aliases => 'DBInstanceIdentifier'
        attribute :name, :aliases => 'LogFileName'
        attribute :size, :aliases => 'Size', :type => :integer
        attribute :last_written, :aliases => 'LastWritten', :type => :time
        attribute :content, :aliases => 'LogFileData'
        attribute :marker, :aliases => 'Marker'
        attribute :more_content_available, :aliases => 'AdditionalDataPending', :type => :boolean

        def content_excerpt(marker=nil)
          result = service.download_db_logfile_portion(self.rds_id, self.name, {:marker => marker})
          merge_attributes(result.body['DownloadDBLogFilePortionResult'])
        end
      end
    end
  end
end
