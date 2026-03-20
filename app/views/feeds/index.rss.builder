xml.instruct! :xml, version: "1.0", encoding: "UTF-8"

xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Personal Blog"
    xml.description "Latest posts from Personal Blog"
    xml.link root_url
    xml.language "en"
    xml.lastBuildDate @posts.first&.published_at&.rfc2822
    xml.tag! "atom:link", href: feed_url(format: :rss), rel: "self", type: "application/rss+xml"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.excerpt
        xml.pubDate post.published_at.rfc2822
        xml.link post_show_url(slug: post.slug)
        xml.guid post_show_url(slug: post.slug), isPermaLink: "true"
      end
    end
  end
end
