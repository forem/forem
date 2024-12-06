module Fog
  module AWS
    class Glacier
      class Job < Fog::Model
        ARCHIVE = 'archive-retrieval'
        INVENTORY = 'inventory-retrieval'

        identity  :id,              :aliases => "JobId"
        attribute :action,          :aliases => "Action"
        attribute :archive_id,      :aliases => "ArchiveId"
        attribute :archive_size,    :aliases => "ArchiveSizeInBytes", :type => :integer
        attribute :completed,       :aliases => "Completed", :type => :boolean
        attribute :completed_at,    :aliases => "CompletionDate", :type => :time
        attribute :created_at,      :aliases => "CreationDate", :type => :time
        attribute :inventory_size,  :aliases => "InventorySizeInBytes", :type => :integer
        attribute :description,     :aliases=> "JobDescription"
        attribute :tree_hash,       :aliases=> "SHA256TreeHash"
        attribute :sns_topic,       :aliases => "SNSTopic"
        attribute :status_code,     :aliases=> "StatusCode"
        attribute :status_message,  :aliases=> "StatusMessage"
        attribute :vault_arn,       :aliases=> "VaultARN"
        attribute :format
        attribute :type

        def ready?
          completed
        end

        def save
          requires :vault, :type
          specification = {'Type' => type, 'ArchiveId' => archive_id, 'Format' => format, 'Description' => description, 'SNSTopic' => sns_topic}.reject{|k,v| v.nil?}

          data = service.initiate_job(vault.id, specification)
          self.id = data.headers['x-amz-job-id']
          reload
        end

        def vault
          @vault
        end

        #pass :range => 1..1234 to only retrieve those bytes
        #pass :io => f to stream the response to that tio
        def get_output(options={})
          if io = options.delete(:io)
            options = options.merge :response_block => lambda {|chunk, remaining_bytes, total_bytes| io.write chunk}
          end
          options['Range'] = options.delete :range
          service.get_job_output(vault.id, id, options)
        end

        private
        def vault=(new_vault)
          @vault = new_vault
        end
      end
    end
  end
end
