require 'thread/pool'
require 'thread_safe'

module EasyTranslate

  module Threadable
    def threaded_process(method, *args)
      texts = args[0]
      options = args[1]
      http_options = args[2]
      options       = options.dup
      batch_size    = options.delete(:batch_size) || 100
      concurrency   = options.delete(:concurrency) || 4
      batches       = Array(texts).each_slice(batch_size).to_a
      if concurrency > 1 && batches.size > 1
        pool          = Thread::Pool.new([concurrency, 1 + (texts.length - 1) / batch_size].min)
        batch_results = ThreadSafe::Array.new
        batches.each_with_index do |texts_batch, i|
          pool.process { batch_results[i] = self.send(method, texts_batch, options, http_options) }
        end
        pool.shutdown
        results = batch_results.reduce(:+)
      else
        results = batches.map { |texts_batch| self.send(method, texts_batch, options, http_options) }.reduce(:+)
      end
      # if they only asked for one, only give one back
      texts.is_a?(String) ? results[0] : results
    ensure
      pool.shutdown! if pool && !pool.shutdown?
    end
  end

end
