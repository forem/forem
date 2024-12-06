# Copyright Cloudinary

class Cloudinary::Migrator
  attr_reader :retrieve, :complete
  attr_accessor :terminate, :in_process
  attr_reader :db
  attr_reader :work, :results, :mutex
  attr_reader :extra_options
  
  
  @@init = false
  def self.init
    return if @@init
    @@init = true

    begin 
      require 'sqlite3'
    rescue LoadError
      raise "Please add sqlite3 to your Gemfile"    
    end
    require 'tempfile'
  end
  
  def json_decode(str)
    Cloudinary::Utils.json_decode(str)
  end
    
  def initialize(options={})
    self.class.init
    
    options[:db_file] = "tmp/migration#{$$}.db" if options[:private_database] && !options[:db_file] 
    @dbfile = options[:db_file] || "tmp/migration.db"
    FileUtils.mkdir_p(File.dirname(@dbfile))
    @db = SQLite3::Database.new @dbfile, :results_as_hash=>true
    @retrieve = options[:retrieve]
    @complete = options[:complete]
    @debug = options[:debug] || false
    @ignore_duplicates = options[:ignore_duplicates]
    @threads = [options[:threads] || 10, 100].min
    @threads = 1 if RUBY_VERSION < "1.9"
    @extra_options = {:api_key=>options[:api_key], :api_secret=>options[:api_secret]}
    @delete_after_done = options[:delete_after_done] || options[:private_database]
    @max_processing = @threads * 10
    @in_process = 0
    @work = Queue.new
    @results = Queue.new
    @mutex = Mutex.new
    @db.execute "
      create table if not exists queue (
        id integer primary key,
        internal_id integer,
        public_id text,
        url text,
        metadata text,
        result string,
        status text,
        updated_at integer
      )
    "
    @db.execute "
      create index if not exists status_idx on queue (
        status
      )
    "
    @db.execute "
      create unique index if not exists internal_id_idx on queue (
        internal_id
      )
    "
    @db.execute "
      create unique index if not exists public_id_idx on queue (
        public_id
      )
    "

    if options[:reset_queue]
      @db.execute("delete from queue")
    end
  end
    
  def register_retrieve(&block)
    @retrieve = block
  end

  def register_complete(&block)
    @complete = block
  end
  
  def process(options={})    
    raise CloudinaryException, "url not given and no retrieve callback given" if options[:url].nil? && self.retrieve.nil?
    raise CloudinaryException, "id not given and retrieve or complete callback given" if options[:id].nil? && (!self.retrieve.nil? || !self.complete.nil?)

    debug("Process: #{options.inspect}")
    start
    process_results    
    wait_for_queue
    options = options.dup
    id = options.delete(:id)
    url = options.delete(:url)
    public_id = options.delete(:public_id)
    row = {
      "internal_id"=>id, 
      "url"=>url, 
      "public_id"=>public_id, 
      "metadata"=>options.to_json,
      "status"=>"processing"      
    }    
    begin
      insert_row(row)
      add_to_work_queue(row)
    rescue SQLite3::ConstraintException
      raise if !@ignore_duplicates
    end
  end
      
  def done
    start
    process_all_pending
    @terminate = true
    1.upto(@threads){self.work << nil} # enough objects to release all waiting threads
    @started = false
    @db.close
    File.delete(@dbfile) if @delete_after_done
  end
  
  def max_given_id
    db.get_first_value("select max(internal_id) from queue").to_i
  end
  
  def close_if_needed(file)
    if file.nil?
      # Do nothing.
    elsif file.respond_to?(:close!) 
      file.close! 
    elsif file.respond_to?(:close)
      file.close
    end
  rescue
    # Ignore errors in closing files
  end  

  def temporary_file(data, filename)  
    file = RUBY_VERSION == "1.8.7" ? Tempfile.new('cloudinary') : Tempfile.new('cloudinary', :encoding => 'ascii-8bit')
    file.unlink
    file.write(data)
    file.rewind
    # Tempfile return path == nil after unlink, which break rest-client              
    class << file
      attr_accessor :original_filename
      def content_type
        "application/octet-stream"                  
      end
    end
    file.original_filename = filename
    file                  
  end

  private

  def update_all(values)
    @db.execute("update queue set #{values.keys.map{|key| "#{key}=?"}.join(",")}", *values.values)
  end
  
  def update_row(row, values)    
    values.merge!("updated_at"=>Time.now.to_i)
    query = ["update queue set #{values.keys.map{|key| "#{key}=?"}.join(",")} where id=?"] + values.values + [row["id"]]
    @db.execute(*query)
    values.each{|key, value| row[key.to_s] = value}
    row    
  end
  
  def insert_row(values)
    values.merge!("updated_at"=>Time.now.to_i)
    @db.execute("insert into queue (#{values.keys.join(",")}) values (#{values.keys.map{"?"}.join(",")})", *values.values)
    values["id"] = @db.last_insert_row_id
  end
  
  def refill_queue(last_id)
    @db.execute("select * from queue where status in ('error', 'processing') and id > ? limit ?", last_id, 10000) do
      |row|
      last_id = row["id"] if row["id"] > last_id
      wait_for_queue
      add_to_work_queue(row)
    end
    last_id
  end 

  def process_results
    while self.results.length > 0
      row = self.results.pop
      result = json_decode(row["result"])      
      debug("Done ID=#{row['internal_id']}, result=#{result.inspect}")
      complete.call(row["internal_id"], result) if complete 
      if result["error"]        
        status = case result["error"]["http_code"]
        when 400, 404 then "fatal" # Problematic request. Not a server problem.
        else "error"
        end
      else
        status = "completed"
      end       
      updates = {:status=>status, :result=>row["result"]}
      updates["public_id"] = result["public_id"] if result["public_id"] && !row["public_id"]
      begin 
        update_row(row, updates)
      rescue SQLite3::ConstraintException
        updates = {:status=>"error", :result=>{:error=>{:message=>"public_id already exists"}}.to_json}
        update_row(row, updates)
      end
    end
  end

  def try_try_again(tries=5)
    retry_count = 0
    begin
      return yield
    rescue
      retry_count++
      raise if retry_count > tries
      sleep rand * 3
      retry
    end  
  end
  
  def start
    return if @started
    @started = true
    @terminate = false
    
    self.work.clear
    
    main = self
    Thread.abort_on_exception = true
    1.upto(@threads) do
      |i|
      Thread.start do
        while !main.terminate
          file = nil
          row = main.work.pop
          next if row.nil?
          begin
            debug "Thread #{i} - processing row #{row.inspect}. #{main.work.length} work waiting. #{main.results.length} results waiting."
            url = row["url"]
            cw = false
            result = nil
            if url.nil? && !self.retrieve.nil?
              data = self.retrieve.call(row["internal_id"])
              if defined?(ActiveRecord::Base) && data.is_a?(ActiveRecord::Base)
                cw = true
                data.save!
              elsif defined?(::CarrierWave) && defined?(Cloudinary::CarrierWave) && data.is_a?(Cloudinary::CarrierWave)
                cw = true
                begin
                  data.model.save! 
                rescue Cloudinary::CarrierWave::UploadError 
                  # upload errors will be handled by the result values.
                end
                result = data.metadata
              elsif data.respond_to?(:read) && data.respond_to?(:path)
                # This is an IO style object, pass as is.
                file = data
              elsif data.nil?
                # Skip
              elsif data.match(/^https?:/)
                url = data
              else
                file = main.temporary_file(data, row["public_id"] || "cloudinaryfile") 
              end
            end
            
            if url || file
              options = main.extra_options.merge(:public_id=>row["public_id"])
              json_decode(row["metadata"]).each do
                |key, value|
                options[key.to_sym] = value
              end
                          
              result = Cloudinary::Uploader.upload(url || file, options.merge(:return_error=>true)) || ({:error=>{:message=>"Received nil from uploader!"}})
            elsif cw
              result ||= {"status" => "saved"}
            else
              result = {"error" => {"message" => "Empty data and url", "http_code"=>404}} 
            end
            main.results << {"id"=>row["id"], "internal_id"=>row["internal_id"], "result"=>result.to_json}
          rescue => e
            $stderr.print "Thread #{i} - Error in processing row #{row.inspect} - #{e}\n"
            debug(e.backtrace.join("\n"))
            sleep 1
          ensure
            main.mutex.synchronize{main.in_process -= 1}
            main.close_if_needed(file)
          end          
        end
      end
    end 
    
    retry_previous_queue # Retry all work from previous iteration before we start processing this one.
  end
  
  def debug(message)
    if @debug
      mutex.synchronize{
        $stderr.print "#{Time.now} Cloudinary::Migrator #{message}\n"
      }
    end
  end

  def retry_previous_queue
    last_id = 0
    begin
      prev_last_id, last_id = last_id, refill_queue(last_id)
    end while last_id > prev_last_id
    process_results    
  end
  
  def process_all_pending
    # Waiting for work to finish. While we are at it, process results.
    while self.in_process > 0      
      process_results
      sleep 0.1
    end
    # Make sure we processed all the results
    process_results
  end
  
  def add_to_work_queue(row)
    self.work << row
    mutex.synchronize{self.in_process += 1}
  end
  
  def wait_for_queue
    # Waiting f
    while self.work.length > @max_processing
      process_results    
      sleep 0.1
    end    
  end

  def self.sample        
    migrator = Cloudinary::Migrator.new(
      :retrieve=>proc{|id| Post.find(id).data}, 
      :complete=>proc{|id, result| a}
      )
    
    Post.find_each(:conditions=>["id > ?", migrator.max_given_id], :select=>"id") do
      |post|
      migrator.process(:id=>post.id, :public_id=>"post_#{post.id}")
    end
    migrator.done
  end 
    
  def self.test  
    posts = {}
    done = {}      
    migrator = Cloudinary::Migrator.new(
      :retrieve=>proc{|id| posts[id]}, 
      :complete=>proc{|id, result| $stderr.print "done #{id} #{result}\n"; done[id] = result}
      )
    start = migrator.max_given_id + 1
    (start..1000).each{|i| posts[i] = "hello#{i}"}
    
    posts.each do
      |id, data|
      migrator.process(:id=>id, :public_id=>"post_#{id}")
    end
    migrator.done
    pp [done.length, start]
  end        
end
