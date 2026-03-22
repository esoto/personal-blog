require "rails_helper"

RSpec.describe "Tags", type: :request do
  describe "GET /tags" do
    context "with no tags" do
      it "returns 200" do
        get tags_path
        expect(response).to have_http_status(:ok)
      end

      it "shows empty state message" do
        get tags_path
        expect(response.body).to include("No tags yet")
      end

      it "sets the page title" do
        get tags_path
        expect(response.body).to include("<title>Tags</title>")
      end

      it "includes og:title meta tag" do
        get tags_path
        expect(response.body).to include('property="og:title" content="Tags — Esteban Soto"')
      end

      it "includes og:description meta tag" do
        get tags_path
        expect(response.body).to include('property="og:description" content="Browse all topics and categories."')
      end
    end

    context "with tags" do
      let!(:ruby_tag) { Tag.create!(name: "Ruby") }
      let!(:rails_tag) { Tag.create!(name: "Rails") }
      let!(:javascript_tag) { Tag.create!(name: "JavaScript") }

      it "returns 200" do
        get tags_path
        expect(response).to have_http_status(:ok)
      end

      it "displays all tags" do
        get tags_path
        expect(response.body).to include("Ruby")
        expect(response.body).to include("Rails")
        expect(response.body).to include("JavaScript")
      end

      it "displays tags in alphabetical order" do
        get tags_path
        tag_section = response.body[response.body.index("Browse posts by topic")..]
        js_pos = tag_section.index("JavaScript")
        rails_pos = tag_section.index("Rails")
        ruby_pos = tag_section.index("Ruby")
        expect(js_pos).to be < rails_pos
        expect(rails_pos).to be < ruby_pos
      end

      it "links each tag to its show page" do
        get tags_path
        expect(response.body).to include(tag_path(slug: ruby_tag.slug))
        expect(response.body).to include(tag_path(slug: rails_tag.slug))
      end

      it "displays post counts" do
        post = Post.create!(
          title: "Ruby Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "A Ruby post"
        )
        post.tags << ruby_tag

        get tags_path
        expect(response.body).to include("Ruby")
      end

      it "shows correct post count for a tag with posts" do
        2.times do |i|
          post = Post.create!(
            title: "Post #{i}",
            body_markdown: "# Content",
            status: :published,
            published_at: 1.day.ago,
            excerpt: "Excerpt #{i}"
          )
          post.tags << ruby_tag
        end

        get tags_path
        body = response.body
        # The Ruby tag card should contain the count 2
        # Extract the link block for Ruby tag using its href
        ruby_link_match = body.match(%r{<a[^>]*href="#{tag_path(slug: ruby_tag.slug)}"[^>]*>(.+?)</a>}m)
        expect(ruby_link_match).not_to be_nil
        expect(ruby_link_match[1]).to include("2")
      end

      it "shows zero count for tags with no posts" do
        get tags_path
        body = response.body
        # Tags with no posts should show count 0
        ruby_link_match = body.match(%r{<a[^>]*href="#{tag_path(slug: ruby_tag.slug)}"[^>]*>(.+?)</a>}m)
        expect(ruby_link_match).not_to be_nil
        expect(ruby_link_match[1]).to include("0")
      end
    end

    context "does not show empty state when tags exist" do
      let!(:tag) { Tag.create!(name: "Ruby") }

      it "does not show the empty state message" do
        get tags_path
        expect(response.body).not_to include("No tags yet")
      end
    end

    context "navigation" do
      it "has a Tags nav link pointing to the tags index" do
        get tags_path
        expect(response.body).to include('href="/tags"')
        # Ensure the Tags link does NOT point to /posts
        nav_section = response.body.match(%r{<nav.*?</nav>}m).to_s
        tags_link = nav_section.match(%r{<a[^>]*>Tags</a>}).to_s
        expect(tags_link).to include("/tags")
        expect(tags_link).not_to include("/posts")
      end
    end
  end

  describe "GET /tags/:slug" do
    let!(:tag) { Tag.create!(name: "Ruby") }

    context "with published posts" do
      let!(:published_post) do
        post = Post.create!(
          title: "Ruby Basics",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "Learn Ruby fundamentals"
        )
        post.tags << tag
        post
      end

      let!(:untagged_post) do
        Post.create!(
          title: "Untagged Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "This post has no tags"
        )
      end

      it "returns 200" do
        get tag_path(slug: tag.slug)
        expect(response).to have_http_status(:ok)
      end

      it "displays the tag name" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby")
      end

      it "shows posts tagged with this tag" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby Basics")
      end

      it "does not show untagged posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Untagged Post")
      end

      it "sets the page title" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Posts tagged with Ruby")
      end

      it "includes OG meta tags with tag name" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include('property="og:title" content="Posts tagged with Ruby')
        expect(response.body).to include('property="og:description" content="Browse all posts tagged with Ruby."')
        expect(response.body).to include('property="og:type" content="website"')
        expect(response.body).to include('property="og:url"')
      end

      it "includes Twitter Card meta tags with tag name" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include('name="twitter:card" content="summary"')
        expect(response.body).to include('name="twitter:title" content="Posts tagged with Ruby')
        expect(response.body).to include('name="twitter:description" content="Browse all posts tagged with Ruby."')
      end

      it "includes a canonical URL" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include('rel="canonical"')
      end
    end

    context "with draft posts" do
      let!(:draft_post) do
        post = Post.create!(
          title: "Draft Ruby Post",
          body_markdown: "# Content",
          status: :draft,
          excerpt: "This is a draft"
        )
        post.tags << tag
        post
      end

      it "does not show draft posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Draft Ruby Post")
      end
    end

    context "with future-dated posts" do
      let!(:future_post) do
        post = Post.create!(
          title: "Future Ruby Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.from_now,
          excerpt: "Coming soon"
        )
        post.tags << tag
        post
      end

      it "does not show future-dated posts" do
        get tag_path(slug: tag.slug)
        expect(response.body).not_to include("Future Ruby Post")
      end
    end

    context "with no published posts" do
      it "shows an empty state message" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("No published posts with this tag yet")
      end
    end

    context "with a non-existent tag" do
      it "returns 404" do
        get tag_path(slug: "nonexistent")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with multiple tags on posts" do
      let!(:other_tag) { Tag.create!(name: "Rails") }

      let!(:multi_tag_post) do
        post = Post.create!(
          title: "Ruby on Rails Guide",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "A guide to Rails"
        )
        post.tags << [ tag, other_tag ]
        post
      end

      it "shows the post when filtering by either tag" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("Ruby on Rails Guide")

        get tag_path(slug: other_tag.slug)
        expect(response.body).to include("Ruby on Rails Guide")
      end

      it "displays the post count" do
        get tag_path(slug: tag.slug)
        expect(response.body).to include("1 post")
      end
    end
  end
end
