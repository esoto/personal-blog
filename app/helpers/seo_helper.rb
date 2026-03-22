module SeoHelper
  SITE_NAME = "Esteban Soto".freeze
  JOB_TITLE = "Full-Stack Developer".freeze
  SITE_DESCRIPTION = "Full-stack developer writing about Ruby, JavaScript, and software engineering.".freeze
  SOCIAL_URLS = [
    "https://github.com/esoto",
    "https://www.linkedin.com/in/soto-esteban/"
  ].freeze

  def json_ld_tag(data)
    tag.script(json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  def website_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => SITE_NAME,
      "url" => root_url,
      "description" => SITE_DESCRIPTION
    }
  end

  def blog_posting_json_ld(post)
    {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => post.title,
      "description" => post.excerpt.presence || truncate(post.body_markdown.to_s, length: 160),
      "url" => post_show_url(slug: post.slug),
      "datePublished" => post.published_at&.iso8601,
      "dateModified" => post.updated_at&.iso8601,
      "author" => person_reference,
      "publisher" => person_reference,
      "keywords" => post.tags.map(&:name)
    }
  end

  def person_json_ld
    {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => SITE_NAME,
      "url" => about_url,
      "jobTitle" => JOB_TITLE,
      "sameAs" => SOCIAL_URLS
    }
  end

  def breadcrumb_json_ld(items)
    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map do |item, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => item[:name],
          "item" => item[:url]
        }
      end
    }
  end

  private

  def person_reference
    {
      "@type" => "Person",
      "name" => SITE_NAME,
      "url" => about_url
    }
  end
end
