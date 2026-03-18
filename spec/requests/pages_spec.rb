require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the homepage successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the hero section" do
      get root_path
      expect(response.body).to include("Software Engineer")
      expect(response.body).to include("Ruby")
      expect(response.body).to include("JavaScript")
    end

    context "with published posts" do
      let!(:post1) do
        Post.create!(
          title: "First Post",
          excerpt: "This is the first post excerpt",
          status: :published,
          published_at: 2.days.ago
        )
      end

      let!(:post2) do
        Post.create!(
          title: "Second Post",
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

      it "limits to 5 posts" do
        6.times do |i|
          Post.create!(
            title: "Post #{i + 3}",
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

    context "with draft posts" do
      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
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
          excerpt: "A post with tags",
          status: :published,
          published_at: 1.day.ago
        )
        post.tags << [ tag1, tag2 ]
        post
      end

      it "displays tags on the post card" do
        get root_path
        expect(response.body).to include("Ruby")
        expect(response.body).to include("Rails")
      end
    end

    context "with mixed post statuses" do
      let!(:published_post) do
        Post.create!(
          title: "Published Post",
          excerpt: "Published excerpt",
          status: :published,
          published_at: 1.day.ago
        )
      end

      let!(:draft_post) do
        Post.create!(
          title: "Draft Post",
          excerpt: "Draft excerpt",
          status: :draft,
          published_at: nil
        )
      end

      let!(:future_post) do
        Post.create!(
          title: "Future Post",
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
