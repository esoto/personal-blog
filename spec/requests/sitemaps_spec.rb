require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  describe "GET /sitemap.xml" do
    let!(:tag) { Tag.create!(name: "Ruby") }

    let!(:published_post) do
      Post.create!(
        title: "Published Post",
        body_markdown: "# Content",
        status: :published,
        published_at: 1.day.ago,
        excerpt: "A published excerpt"
      )
    end

    let!(:older_published_post) do
      Post.create!(
        title: "Older Published Post",
        body_markdown: "# Older content",
        status: :published,
        published_at: 3.days.ago,
        excerpt: "An older excerpt"
      )
    end

    let!(:draft_post) do
      Post.create!(
        title: "Draft Post",
        body_markdown: "# Draft content",
        status: :draft,
        excerpt: "A draft excerpt"
      )
    end

    it "returns a successful response" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:ok)
    end

    it "returns XML content type" do
      get "/sitemap.xml"
      expect(response.content_type).to include("application/xml")
    end

    it "contains valid XML with urlset namespace" do
      get "/sitemap.xml"
      xml = Nokogiri::XML(response.body)

      urlset = xml.at_xpath("//xmlns:urlset", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      expect(urlset).to be_present
    end

    it "includes root URL" do
      get "/sitemap.xml"
      expect(response.body).to include(root_url)
    end

    it "includes about URL" do
      get "/sitemap.xml"
      expect(response.body).to include(about_url)
    end

    it "includes posts index URL" do
      get "/sitemap.xml"
      expect(response.body).to include(posts_url)
    end

    it "includes tags index URL" do
      get "/sitemap.xml"
      expect(response.body).to include(tags_url)
    end

    it "includes published post URLs with lastmod dates" do
      get "/sitemap.xml"
      xml = Nokogiri::XML(response.body)
      ns = { "s" => "http://www.sitemaps.org/schemas/sitemap/0.9" }

      urls = xml.xpath("//s:url", ns)
      post_url_node = urls.detect { |u| u.at_xpath("s:loc", ns)&.text&.include?("/posts/#{published_post.slug}") }

      expect(post_url_node).to be_present
      lastmod = post_url_node.at_xpath("s:lastmod", ns)&.text
      expect(lastmod).to eq(published_post.updated_at.iso8601)
    end

    it "includes tag URLs" do
      get "/sitemap.xml"
      expect(response.body).to include(tag_url(slug: tag.slug))
    end

    it "excludes draft posts" do
      get "/sitemap.xml"
      expect(response.body).not_to include("/posts/#{draft_post.slug}")
    end

    it "sets cache headers" do
      get "/sitemap.xml"
      cache_control = response.headers["Cache-Control"]
      expect(cache_control).to include("public")
      expect(cache_control).to include("max-age=3600")
    end

    context "when there are no published posts" do
      before { Post.destroy_all }

      it "returns a successful response with empty post entries" do
        get "/sitemap.xml"
        expect(response).to have_http_status(:ok)

        xml = Nokogiri::XML(response.body)
        ns = { "s" => "http://www.sitemaps.org/schemas/sitemap/0.9" }
        urls = xml.xpath("//s:url/s:loc", ns).map(&:text)

        expect(urls).to include(root_url)
        expect(urls).to include(about_url)
        expect(urls).not_to include(a_string_matching(%r{/posts/}))
      end
    end
  end
end
