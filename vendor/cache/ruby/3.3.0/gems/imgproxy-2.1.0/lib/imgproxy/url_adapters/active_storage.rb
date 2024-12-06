module Imgproxy
  class UrlAdapters
    # Adapter for ActiveStorage
    #
    #   Imgproxy.configure do |config|
    #     config.url_adapters.add Imgproxy::UrlAdapters::ActiveStorage.new
    #   end
    #
    #   Imgproxy.url_for(user.avatar)
    class ActiveStorage
      def applicable?(image)
        image.is_a?(::ActiveStorage::Attached::One) ||
          image.is_a?(::ActiveStorage::Attachment) ||
          image.is_a?(::ActiveStorage::Blob)
      end

      def url(image)
        return s3_url(image) if use_s3_url(image)
        return gcs_url(image) if use_gcs_url(image)

        Rails.application.routes.url_helpers.url_for(image)
      end

      private

      def s3_url(image)
        "s3://#{service(image).bucket.name}/#{image.key}"
      end

      def use_s3_url(image)
        config.use_s3_urls && service(image).is_a?(::ActiveStorage::Service::S3Service)
      end

      def gcs_url(image)
        "gs://#{config.gcs_bucket}/#{image.key}"
      end

      def use_gcs_url(image)
        config.use_gcs_urls && service(image).is_a?(::ActiveStorage::Service::GCSService)
      end

      def service(image)
        unwrap_service(image.service)
      end

      def unwrap_service(service)
        return service unless defined?(::ActiveStorage::Service::MirrorService)
        return service unless service.is_a?(::ActiveStorage::Service::MirrorService)
        unwrap_service(service.primary)
      end

      def config
        Imgproxy.config
      end
    end
  end
end
