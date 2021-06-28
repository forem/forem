# encoding: UTF-8

# rubocop:disable Metrics/BlockLength

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title user ? user.name : community_name
    xml.author user ? user.name : community_name
    xml.description user ? user.tag_line : Settings::Community.community_description
    xml.link user ? app_url(user.path) : app_url
    xml.language "en"
    if user
      xml.image do
        xml.url user.profile_image_90
        xml.title "#{user.name} profile image"
        xml.link app_url(user.path)
      end
    end
    articles.each do |article|
      xml.item do
        xml.title article.title
        xml.author(user.instance_of?(User) ? user.name : article.user.name)
        xml.pubDate article.published_at.to_s(:rfc822) if article.published_at
        xml.link app_url(article.path)
        xml.guid app_url(article.path)
        xml.description sanitize(article.plain_html, tags: allowed_tags, attributes: allowed_attributes)
        article.tag_list.each do |tag_name|
          xml.category tag_name
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
