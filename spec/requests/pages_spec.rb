require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the homepage successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the hero section" do
      get root_path
      expect(response.body).to include("Esteban Soto")
      expect(response.body).to include("Rails developer since 2012")
      expect(response.body).to include("databases")
    end

    it "keeps Full-Stack Developer in the document title for SEO" do
      get root_path
      expect(response.body).to include("<title>Esteban Soto — Full-Stack Developer")
    end

    it "sets a descriptive page title" do
      get root_path
      expect(response.body).to include("<title>Esteban Soto")
    end

    it "includes lang attribute on html tag" do
      get root_path
      expect(response.body).to include('<html lang="en">')
    end

    it "includes OG meta tags" do
      get root_path
      expect(response.body).to include('property="og:title"')
      expect(response.body).to include("Esteban Soto")
      expect(response.body).to include('property="og:description"')
      expect(response.body).to include('property="og:type"')
      expect(response.body).to include('property="og:url"')
    end

    it "includes Twitter Card meta tags" do
      get root_path
      expect(response.body).to include('name="twitter:card" content="summary"')
      expect(response.body).to include('name="twitter:title"')
      expect(response.body).to include('name="twitter:description"')
    end

    it "includes a canonical URL" do
      get root_path
      expect(response.body).to include('rel="canonical"')
    end

    it "includes JSON-LD structured data for WebSite" do
      get root_path
      expect(response.body).to include('application/ld+json')
      expect(response.body).to include('"@type":"WebSite"')
      expect(response.body).to include('"name":"Esteban Soto"')
    end

    it "does not leak the deprecated accent-blue tokens onto the public home page" do
      # Public templates are migrated to emerald (accent-green). The blue
      # accent is reserved for admin UI. This guard prevents future template
      # changes from accidentally reintroducing accent-blue on a public page.
      get root_path
      expect(response.body).not_to match(/text-accent-blue|bg-accent-blue|border-accent-blue|hover:text-accent-blue|hover:border-accent-blue|hover:bg-accent-blue|ring-accent-blue|from-accent-blue|to-accent-blue/)
    end

    it "applies the font-display serif utility to the hero h1" do
      # The signature expressive channel of the design system is editorial
      # heading typography (Fraunces). This guard ensures the hero h1
      # always carries the font-display class that triggers the serif.
      get root_path
      expect(response.body).to match(/<h1[^>]*class="[^"]*\bfont-display\b/)
    end

    it "applies font-display to the 'Latest Posts' section heading" do
      get root_path
      expect(response.body).to match(/<h2[^>]*class="[^"]*\bfont-display\b[^"]*"[^>]*>[\s\S]*?Latest[\s\S]*?Posts/)
    end

    it "loads all three design-system fonts from Google Fonts with display:swap" do
      # A typo in the Google Fonts URL (e.g. dropping `opsz` from Fraunces)
      # would silently break variable-axis loading. This asserts the URL
      # contents stay intact.
      get root_path
      expect(response.body).to include("family=Fraunces")
      expect(response.body).to include("family=Inter")
      expect(response.body).to include("family=JetBrains+Mono")
      expect(response.body).to include("display=swap")
    end

    context "with published posts" do
      let!(:post1) do
        Post.create!(
          title: "First Post",
          body_markdown: "# Content",
          excerpt: "This is the first post excerpt",
          status: :published,
          published_at: 2.days.ago
        )
      end

      let!(:post2) do
        Post.create!(
          title: "Second Post",
          body_markdown: "# Content",
          excerpt: "This is the second post excerpt",
          status: :published,
          published_at: 1.day.ago
        )
      end

      it "displays published posts on the homepage" do
        get root_path
        expect(response.body).to include("First Post")
        expect(response.body).to include("Second Post")
        expect(response.body).to include("This is the first post excerpt")
        expect(response.body).to include("This is the second post excerpt")
      end

      it "displays posts in reverse chronological order (most recent first)" do
        get root_path
        body = response.body
        second_pos = body.index("Second Post")
        first_pos = body.index("First Post")
        expect(second_pos).to be < first_pos
      end

      it "renders the most recent post as a featured card" do
        get root_path
        # Featured card uses the "★ Latest" badge and a left-border accent
        expect(response.body).to include("★ Latest")
        expect(response.body).to include("border-l-accent-green")
        # The featured card should render the most recent post (Second Post)
        featured_marker_pos = response.body.index("★ Latest")
        expect(featured_marker_pos).not_to be_nil
        # Second Post title should appear close to the featured marker
        featured_section = response.body[featured_marker_pos..(featured_marker_pos + 1500)]
        expect(featured_section).to include("Second Post")
      end

      it "shows a 'Latest' hero hint linking to the most recent post" do
        get root_path
        expect(response.body).to match(/Latest:.*Second Post/m)
      end

      it "limits to 5 posts" do
        6.times do |i|
          Post.create!(
            title: "Post #{i + 3}",
            body_markdown: "# Content",
            excerpt: "Excerpt #{i + 3}",
            status: :published,
            published_at: (10 - i).days.ago
          )
        end

        get root_path
        # 8 total posts, homepage shows only 5 most recent
        # Each post card renders exactly one <h3> heading
        expect(response.body.scan(/<h3/).count).to eq(5)
      end
    end

    context "with a single published post" do
      let!(:only_post) do
        Post.create!(
          title: "Solo Post",
          body_markdown: "# Content",
          excerpt: "The only post",
          status: :published,
          published_at: 1.day.ago
        )
      end

      it "renders the single post via the featured card and no grid" do
        get root_path
        # Featured card renders
        expect(response.body).to include("Solo Post")
        expect(response.body).to include("★ Latest")
        # Only one post card on the page (the featured one — standard post_card
        # grid is hidden because @posts.length > 1 is false)
        expect(response.body.scan(/<h3/).count).to eq(1)
      end
    end

    context "with draft posts" do
      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          body_markdown: "# Content",
          excerpt: "This is a draft",
          status: :draft,
          published_at: 1.day.ago
        )
      end

      it "does not display draft posts" do
        get root_path
        expect(response.body).not_to include("Draft Post")
      end
    end

    context "with future-dated posts" do
      let!(:future_post) do
        Post.create!(
          title: "Future Post",
          body_markdown: "# Content",
          excerpt: "This is in the future",
          status: :published,
          published_at: 1.day.from_now
        )
      end

      it "does not display future-dated posts" do
        get root_path
        expect(response.body).not_to include("Future Post")
      end
    end

    context "with no posts" do
      it "displays the 'No posts yet' message" do
        get root_path
        expect(response.body).to include("No posts yet")
      end
    end

    context "with posts that have tags" do
      let!(:tag1) { Tag.create!(name: "Ruby") }
      let!(:tag2) { Tag.create!(name: "Rails") }

      let!(:post_with_tags) do
        post = Post.create!(
          title: "Tagged Post",
          body_markdown: "# Content",
          excerpt: "A post with tags",
          status: :published,
          published_at: 1.day.ago
        )
        post.tags << [ tag1, tag2 ]
        post
      end

      it "displays tags on the post card" do
        get root_path
        # Use tag-specific route helpers so the assertion can't be satisfied
        # by the hero tagline mentioning "Rails" in prose.
        expect(response.body).to include(tag_path(slug: tag1.slug))
        expect(response.body).to include(tag_path(slug: tag2.slug))
      end
    end

    context "with mixed post statuses" do
      let!(:published_post) do
        Post.create!(
          title: "Published Post",
          body_markdown: "# Content",
          excerpt: "Published excerpt",
          status: :published,
          published_at: 1.day.ago
        )
      end

      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          body_markdown: "# Content",
          excerpt: "Draft excerpt",
          status: :draft,
          published_at: nil
        )
      end

      let!(:future_post) do
        Post.create!(
          title: "Future Post",
          body_markdown: "# Content",
          excerpt: "Future excerpt",
          status: :published,
          published_at: 1.day.from_now
        )
      end

      it "only shows the published, past-dated post" do
        get root_path
        expect(response.body).to include("Published Post")
        expect(response.body).not_to include("Draft Post")
        expect(response.body).not_to include("Future Post")
      end
    end
  end
end
