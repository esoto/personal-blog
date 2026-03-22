require "rails_helper"

RSpec.describe SeoHelper, type: :helper do
  before do
    allow(helper).to receive(:root_url).and_return("http://test.host/")
    allow(helper).to receive(:about_url).and_return("http://test.host/about")
  end

  describe "#json_ld_tag" do
    it "renders a script tag with type application/ld+json" do
      data = { "@type" => "WebSite", "name" => "Test" }
      result = helper.json_ld_tag(data)

      expect(result).to include('type="application/ld+json"')
      expect(result).to include("<script")
      expect(result).to include("</script>")
    end

    it "contains valid JSON in the script tag" do
      data = { "@type" => "WebSite", "name" => "Test" }
      result = helper.json_ld_tag(data)

      json_content = result.match(%r{<script[^>]*>(.*)</script>}m)[1]
      parsed = JSON.parse(json_content)
      expect(parsed["@type"]).to eq("WebSite")
      expect(parsed["name"]).to eq("Test")
    end

    it "escapes HTML entities for XSS safety" do
      data = { "name" => "<script>alert('xss')</script>" }
      result = helper.json_ld_tag(data)

      expect(result).not_to include("<script>alert")
    end
  end

  describe "#website_json_ld" do
    subject(:json_ld) { helper.website_json_ld }

    it "returns correct @context" do
      expect(json_ld["@context"]).to eq("https://schema.org")
    end

    it "returns correct @type" do
      expect(json_ld["@type"]).to eq("WebSite")
    end

    it "includes the site name" do
      expect(json_ld["name"]).to eq("Esteban Soto")
    end

    it "includes the root URL" do
      expect(json_ld["url"]).to eq("http://test.host/")
    end

    it "includes a description" do
      expect(json_ld["description"]).to be_present
    end
  end

  describe "#blog_posting_json_ld" do
    let(:tag1) { Tag.create!(name: "Ruby") }
    let(:tag2) { Tag.create!(name: "Rails") }
    let(:post) do
      Post.create!(
        title: "Test Post",
        body_markdown: "This is the body content for the test post.",
        excerpt: "Test excerpt",
        status: :published,
        published_at: Time.zone.parse("2025-01-15 10:00:00")
      )
    end

    before do
      allow(helper).to receive(:post_show_url).with(slug: post.slug).and_return("http://test.host/posts/#{post.slug}")
    end

    subject(:json_ld) { helper.blog_posting_json_ld(post) }

    it "returns correct @type" do
      expect(json_ld["@type"]).to eq("BlogPosting")
    end

    it "includes the headline" do
      expect(json_ld["headline"]).to eq("Test Post")
    end

    it "includes the excerpt as description" do
      expect(json_ld["description"]).to eq("Test excerpt")
    end

    it "includes the post URL" do
      expect(json_ld["url"]).to eq("http://test.host/posts/#{post.slug}")
    end

    it "includes datePublished in ISO8601 format" do
      expect(json_ld["datePublished"]).to eq(post.published_at.iso8601)
    end

    it "includes dateModified in ISO8601 format" do
      expect(json_ld["dateModified"]).to eq(post.updated_at.iso8601)
    end

    it "includes author as a Person reference" do
      expect(json_ld["author"]["@type"]).to eq("Person")
      expect(json_ld["author"]["name"]).to eq("Esteban Soto")
    end

    it "includes publisher as a Person reference" do
      expect(json_ld["publisher"]["@type"]).to eq("Person")
      expect(json_ld["publisher"]["name"]).to eq("Esteban Soto")
    end

    it "includes keywords from tags" do
      post.tags << [ tag1, tag2 ]
      expect(json_ld["keywords"]).to contain_exactly("Ruby", "Rails")
    end

    context "with no excerpt" do
      let(:post_no_excerpt) do
        Post.create!(
          title: "No Excerpt Post",
          body_markdown: "This is the body content that should be truncated for the description field.",
          excerpt: nil,
          status: :published,
          published_at: 1.day.ago
        )
      end

      before do
        allow(helper).to receive(:post_show_url).with(slug: post_no_excerpt.slug).and_return("http://test.host/posts/#{post_no_excerpt.slug}")
      end

      it "falls back to truncated body_markdown" do
        result = helper.blog_posting_json_ld(post_no_excerpt)
        expect(result["description"]).to be_present
        expect(result["description"].length).to be <= 160
      end
    end

    context "with no tags" do
      it "returns empty keywords array" do
        expect(json_ld["keywords"]).to eq([])
      end
    end
  end

  describe "#person_json_ld" do
    subject(:json_ld) { helper.person_json_ld }

    it "returns correct @type" do
      expect(json_ld["@type"]).to eq("Person")
    end

    it "includes the name" do
      expect(json_ld["name"]).to eq("Esteban Soto")
    end

    it "includes the about URL" do
      expect(json_ld["url"]).to eq("http://test.host/about")
    end

    it "includes jobTitle" do
      expect(json_ld["jobTitle"]).to eq("Full-Stack Developer")
    end

    it "includes sameAs links" do
      expect(json_ld["sameAs"]).to include("https://github.com/esoto")
      expect(json_ld["sameAs"]).to include("https://www.linkedin.com/in/soto-esteban/")
    end
  end

  describe "#breadcrumb_json_ld" do
    let(:items) do
      [
        { name: "Home", url: "http://test.host/" },
        { name: "Posts", url: "http://test.host/posts" },
        { name: "My Post", url: "http://test.host/posts/my-post" }
      ]
    end

    subject(:json_ld) { helper.breadcrumb_json_ld(items) }

    it "returns correct @type" do
      expect(json_ld["@type"]).to eq("BreadcrumbList")
    end

    it "generates correct number of list items" do
      expect(json_ld["itemListElement"].length).to eq(3)
    end

    it "assigns correct positions starting at 1" do
      positions = json_ld["itemListElement"].map { |item| item["position"] }
      expect(positions).to eq([ 1, 2, 3 ])
    end

    it "includes correct names" do
      names = json_ld["itemListElement"].map { |item| item["name"] }
      expect(names).to eq(%w[Home Posts My\ Post])
    end

    it "includes correct URLs" do
      urls = json_ld["itemListElement"].map { |item| item["item"] }
      expect(urls).to eq([
        "http://test.host/",
        "http://test.host/posts",
        "http://test.host/posts/my-post"
      ])
    end

    it "sets each element @type to ListItem" do
      types = json_ld["itemListElement"].map { |item| item["@type"] }
      expect(types).to all(eq("ListItem"))
    end
  end
end
