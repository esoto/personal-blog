require "rails_helper"

RSpec.describe "Posts", type: :request do
  describe "GET /posts" do
    context "with published posts" do
      let!(:published_post) do
        Post.create!(
          title: "Published Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "This is a published post"
        )
      end

      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          body_markdown: "# Content",
          status: :draft,
          excerpt: "This is a draft post"
        )
      end

      it "returns 200" do
        get posts_path
        expect(response).to have_http_status(:ok)
      end

      it "shows published posts" do
        get posts_path
        expect(response.body).to include("Published Post")
      end

      it "includes OG meta tags" do
        get posts_path
        expect(response.body).to include('property="og:title" content="Posts')
        expect(response.body).to include('property="og:description"')
        expect(response.body).to include('property="og:type" content="website"')
        expect(response.body).to include('property="og:url"')
      end

      it "includes Twitter Card meta tags" do
        get posts_path
        expect(response.body).to include('name="twitter:card" content="summary"')
        expect(response.body).to include('name="twitter:title" content="Posts')
        expect(response.body).to include('name="twitter:description"')
      end

      it "includes a canonical URL" do
        get posts_path
        expect(response.body).to include('rel="canonical"')
      end

      it "does not show draft posts" do
        get posts_path
        expect(response.body).not_to include("Draft Post")
      end
    end

    context "with pagination" do
      before do
        12.times do |i|
          Post.create!(
            title: "Article-#{format('%02d', i + 1)}",
            body_markdown: "# Content",
            status: :published,
            published_at: (12 - i).days.ago,
            excerpt: "Excerpt #{i + 1}"
          )
        end
      end

      it "shows only 10 posts on page 1" do
        get posts_path
        # Newest first: Article-12, 11, ..., 03
        expect(response.body).to include("Article-12")
        expect(response.body).to include("Article-03")
        expect(response.body).not_to include("Article-02")
      end

      it "shows remaining posts on page 2" do
        get posts_path(page: 2)
        # Oldest 2: Article-02, Article-01
        expect(response.body).to include("Article-02")
        expect(response.body).to include("Article-01")
        expect(response.body).not_to include("Article-12")
      end

      it "clamps page=0 to page 1" do
        get posts_path(page: 0)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Article-12")
      end

      it "clamps negative page to page 1" do
        get posts_path(page: -5)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Article-12")
      end

      it "treats non-numeric page as page 1" do
        get posts_path(page: "abc")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Article-12")
      end
    end
  end

  describe "GET /posts/:slug" do
    context "with a published post" do
      let!(:post) do
        Post.create!(
          title: "Test Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: "Test excerpt"
        )
      end

      it "returns 200" do
        get post_show_path(slug: post.slug)
        expect(response).to have_http_status(:ok)
      end

      it "displays the post title" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include("Test Post")
      end

      it "includes highlight.js CDN stylesheet" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include("highlightjs/cdn-assets")
        expect(response.body).to include("github-dark.min.css")
      end

      it "includes highlight.js CDN script" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include("highlight.min.js")
      end

      it "includes the highlight Stimulus controller" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('data-controller="highlight')
      end

      it "wires clipboard Stimulus controllers per code block (figure scope)" do
        # Each code block figure carries its own `data-controller="clipboard"`
        # so the copy button's target lookup is scoped to the block it lives
        # in. The outer prose-dark wrapper no longer needs a clipboard
        # controller — the figures handle it.
        post_with_code = Post.create!(
          title: "Code Post",
          slug: "code-post",
          body_markdown: "```ruby\nputs 'hi'\n```",
          status: :published,
          published_at: 1.day.ago
        )
        get post_show_path(slug: post_with_code.slug)
        expect(response.body).to include('<figure class="code-block" data-controller="clipboard">')
        expect(response.body).to include('data-clipboard-target="button"')
      end

      it "includes OG meta tags with post title" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('property="og:title" content="Test Post"')
        expect(response.body).to include('property="og:description" content="Test excerpt"')
        expect(response.body).to include('property="og:type" content="article"')
        expect(response.body).to include('property="og:url"')
      end

      it "includes Twitter Card meta tags with post title" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('name="twitter:card" content="summary"')
        expect(response.body).to include('name="twitter:title" content="Test Post"')
        expect(response.body).to include('name="twitter:description" content="Test excerpt"')
      end

      it "includes a canonical URL" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('rel="canonical"')
      end

      it "includes JSON-LD structured data for BlogPosting" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('application/ld+json')
        expect(response.body).to include('"@type":"BlogPosting"')
        expect(response.body).to include('"headline":"Test Post"')
      end

      it "includes JSON-LD BreadcrumbList" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include('"@type":"BreadcrumbList"')
        expect(response.body).to include('"name":"Home"')
        expect(response.body).to include('"name":"Posts"')
        expect(response.body).to include('"name":"Test Post"')
      end

      it "displays reading time" do
        get post_show_path(slug: post.slug)
        expect(response.body).to include("min read")
      end
    end

    context "with a published post without excerpt" do
      let!(:post_no_excerpt) do
        Post.create!(
          title: "No Excerpt Post",
          body_markdown: "# Content",
          status: :published,
          published_at: 1.day.ago,
          excerpt: nil
        )
      end

      it "falls back to truncated body for OG description" do
        get post_show_path(slug: post_no_excerpt.slug)
        expect(response.body).to include('property="og:description"')
        expect(response.body).to include('name="twitter:description"')
      end
    end

    context "with a draft post" do
      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          body_markdown: "# Content",
          status: :draft,
          excerpt: "Draft excerpt"
        )
      end

      it "returns 404" do
        get post_show_path(slug: draft_post.slug)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a non-existent slug" do
      it "returns 404" do
        get post_show_path(slug: "nonexistent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
