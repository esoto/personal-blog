require "rails_helper"

RSpec.describe "API V1 Stats", type: :request do
  before do
    ENV["BLOG_API_TOKEN"] = "test-api-token"
  end

  describe "GET /api/v1/stats" do
    it "returns 401 without authentication" do
      get "/api/v1/stats"
      expect(response).to have_http_status(:unauthorized)
    end

    context "when authenticated" do
      it "returns correct stats with no data" do
        get "/api/v1/stats", headers: api_headers
        expect(response).to have_http_status(:ok)

        stats = response.parsed_body
        expect(stats).to eq(
          "total_posts" => 0,
          "published_posts" => 0,
          "draft_posts" => 0,
          "pending_comments" => 0,
          "total_tags" => 0
        )
      end

      it "returns correct post counts" do
        Post.create!(title: "Published", body_markdown: "# Content", status: :published, published_at: 1.day.ago)
        Post.create!(title: "Draft", body_markdown: "# Content", status: :draft)
        Post.create!(title: "Another Published", body_markdown: "# Content", status: :published, published_at: 2.days.ago)

        get "/api/v1/stats", headers: api_headers
        stats = response.parsed_body

        expect(stats["total_posts"]).to eq(3)
        expect(stats["published_posts"]).to eq(2)
        expect(stats["draft_posts"]).to eq(1)
      end

      it "returns correct pending comment count" do
        post = Post.create!(title: "Post", body_markdown: "# Content", status: :published, published_at: 1.day.ago)
        post.comments.create!(author_name: "Alice", email: "a@test.com", body: "Pending", status: :pending)
        post.comments.create!(author_name: "Bob", email: "b@test.com", body: "Approved", status: :approved)
        post.comments.create!(author_name: "Carol", email: "c@test.com", body: "Spam", status: :spam)
        post.comments.create!(author_name: "Dave", email: "d@test.com", body: "Also pending", status: :pending)

        get "/api/v1/stats", headers: api_headers
        stats = response.parsed_body

        expect(stats["pending_comments"]).to eq(2)
      end

      it "returns correct tag count" do
        Tag.create!(name: "Ruby")
        Tag.create!(name: "Rails")
        Tag.create!(name: "JavaScript")

        get "/api/v1/stats", headers: api_headers
        stats = response.parsed_body

        expect(stats["total_tags"]).to eq(3)
      end
    end
  end
end
