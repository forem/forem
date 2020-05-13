# encoding: UTF-8

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title @user ? @user.name : community_qualified_name
    xml.author @user ? @user.name : community_qualified_name
    xml.description  @user ? @user.summary : SiteConfig.community_description
    xml.link @user ? app_url(@user.path) : app_url
    xml.language "en"

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.author(@user && @user.class.name == "User" ? @user.name : article.user.name)
        xml.pubDate article.published_at.to_s(:rfc822) if article.published_at
        xml.link app_url(article.path)
        xml.guid app_url(article.path)
        xml.description sanitize article.processed_html,
                                 tags: %w[strong em a table tbody thead tfoot th tr td col colgroup del p h1 h2 h3 h4 h5 h6 blockquote iframe time div span i em u b ul ol li dd dl dt q code pre img sup cite center br small],
                                 attributes: %w[href strong em class ref rel src title alt colspan height width size rowspan span value start data-conversation data-lang id]
      end
    end
  end
end
