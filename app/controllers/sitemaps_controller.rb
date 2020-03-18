class SitemapsController < ApplicationController
  def show
    path = if params[:id] == "sitemap"
             "sitemap.xml.gz"
           else
             "#{params[:id]}/sitemap.xml.gz"
           end
    redirect_to "https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com/sitemaps/#{path}"
  end
end
