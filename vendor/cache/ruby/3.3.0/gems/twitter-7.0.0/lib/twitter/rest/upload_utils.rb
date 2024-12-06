require 'twitter/rest/request'

module Twitter
  module REST
    module UploadUtils
    private

      # Uploads images and videos. Videos require multiple requests and uploads in chunks of 5 Megabytes.
      # The only supported video format is mp4.
      #
      # @see https://developer.twitter.com/en/docs/media/upload-media/uploading-media/media-best-practices
      def upload(media, media_category_prefix: 'tweet')
        return chunk_upload(media, 'video/mp4', "#{media_category_prefix}_video") if File.extname(media) == '.mp4'
        return chunk_upload(media, 'image/gif', "#{media_category_prefix}_gif") if File.extname(media) == '.gif' && File.size(media) > 5_000_000

        Twitter::REST::Request.new(self, :multipart_post, 'https://upload.twitter.com/1.1/media/upload.json', key: :media, file: media).perform
      end

      # @raise [Twitter::Error::TimeoutError] Error raised when the upload is longer than the value specified in Twitter::Client#timeouts[:upload].
      # @raise [Twitter::Error::MediaError] Error raised when Twitter return an error about a media which is not mapped by the gem.
      # @raise [Twitter::Error::MediaInternalError] Error raised when Twitter returns an InternalError error.
      # @raise [Twitter::Error::InvalidMedia] Error raised when Twitter returns an InvalidMedia error.
      # @raise [Twitter::Error::UnsupportedMedia] Error raised when Twitter returns an UnsupportedMedia error.
      # @see https://developer.twitter.com/en/docs/media/upload-media/uploading-media/chunked-media-upload
      def chunk_upload(media, media_type, media_category)
        Timeout.timeout(timeouts&.fetch(:upload, nil), Twitter::Error::TimeoutError) do
          init = Twitter::REST::Request.new(self, :post, 'https://upload.twitter.com/1.1/media/upload.json',
                                            command: 'INIT',
                                            media_type: media_type,
                                            media_category: media_category,
                                            total_bytes: media.size).perform
          append_media(media, init[:media_id])
          media.close
          finalize_media(init[:media_id])
        end
      end

      # @see https://developer.twitter.com/en/docs/media/upload-media/api-reference/post-media-upload-append
      def append_media(media, media_id)
        until media.eof?
          chunk = media.read(5_000_000)
          seg ||= -1
          Twitter::REST::Request.new(self, :multipart_post, 'https://upload.twitter.com/1.1/media/upload.json',
                                     command: 'APPEND',
                                     media_id: media_id,
                                     segment_index: seg += 1,
                                     key: :media,
                                     file: StringIO.new(chunk)).perform
        end
      end

      # @see https://developer.twitter.com/en/docs/media/upload-media/api-reference/post-media-upload-finalize
      # @see https://developer.twitter.com/en/docs/media/upload-media/api-reference/get-media-upload-status
      def finalize_media(media_id)
        response = Twitter::REST::Request.new(self, :post, 'https://upload.twitter.com/1.1/media/upload.json',
                                              command: 'FINALIZE', media_id: media_id).perform
        loop do
          return response if !response[:processing_info] || %w[failed succeeded].include?(response[:processing_info][:state])

          sleep(response[:processing_info][:check_after_secs])
          response = Twitter::REST::Request.new(self, :get, 'https://upload.twitter.com/1.1/media/upload.json',
                                                command: 'STATUS', media_id: media_id).perform
        end
        response
      end
    end
  end
end
