namespace :s3_direct_upload do
  desc "Removes old uploads from specified s3 bucket/directory -- Useful when uploads are processed into another directory"
  task :clean_remote_uploads => :environment do
    require 'thread'
    require 'fog'

    s3     = Fog::Storage::AWS.new(aws_access_key_id: S3DirectUpload.config.access_key_id, aws_secret_access_key: S3DirectUpload.config.secret_access_key)
    bucket = S3DirectUpload.config.bucket
    prefix = S3DirectUpload.config.prefix_to_clean || "uploads/#{2.days.ago.strftime('%Y%m%d')}"

    queue         = Queue.new
    semaphore     = Mutex.new
    threads       = []
    thread_count  = 20
    total_listed  = 0
    total_deleted = 0

    threads << Thread.new do
      Thread.current[:name] = "get files"
      # Get all the files from this bucket. Fog handles pagination internally.
      s3.directories.get("#{bucket}").files.all({prefix: prefix}).each do |file|
        queue.enq(file)
        total_listed += 1
      end
      # Add a final EOF message to signal the deletion threads to stop.
      thread_count.times { queue.enq(:EOF) }
    end

    # Delete all the files in the queue until EOF with N threads.
    thread_count.times do |count|
      threads << Thread.new(count) do |number|
        Thread.current[:name] = "delete files(#{number})"
        # Dequeue until EOF.
        file = nil
        while file != :EOF
          # Dequeue the latest file and delete it. (Will block until it gets a new file.)
          file = queue.deq
          unless file == :EOF
            file.destroy
            puts %Q{Deleted file with key: "#{file.key}"}
          end
          # Increment the global synchronized counter.
          semaphore.synchronize {total_deleted += 1}
        end
      end
    end

    # Wait for the threads to finish.
    threads.each do |t|
      begin
        t.join
      rescue RuntimeError => e
        puts "Failure on thread #{t[:name]}: #{e.message}"
      end
    end
  end
end
