xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
latest_post = @posts.first
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Root
  xml.url do
    xml.loc root_url
    xml.lastmod latest_post&.published_at&.iso8601
  end

  # About
  xml.url do
    xml.loc about_url
  end

  # Posts index
  xml.url do
    xml.loc posts_url
    xml.lastmod latest_post&.published_at&.iso8601
  end

  # Tags index
  xml.url do
    xml.loc tags_url
  end

  # Individual posts
  @posts.each do |post|
    xml.url do
      xml.loc post_show_url(slug: post.slug)
      xml.lastmod post.updated_at.iso8601
    end
  end

  # Individual tags
  @tags.each do |tag|
    xml.url do
      xml.loc tag_url(slug: tag.slug)
    end
  end
end
