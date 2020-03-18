# This eagerload our custom ReverseMarkdown::Converters and allows it to be autoreloaded
# in development.
#
# Because files are eagerloaded in production, this fix is only
# applicable in development (and test, when needed)

if Rails.env.development? || Rails.env.test?
  Rails.application.config.to_prepare do
    Dir.glob(Rails.root.join("app/lib/reverse_markdown/converters/*.rb")).sort.each do |filename|
      require_dependency filename
    end
  end
end
