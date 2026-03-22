require "rails_helper"

RSpec.describe "API V1 Posts", type: :request do
  around do |example|
    original = ENV["BLOG_API_TOKEN"]
    ENV["BLOG_API_TOKEN"] = "test-api-token"
    example.run
  ensure
    original ? ENV["BLOG_API_TOKEN"] = original : ENV.delete("BLOG_API_TOKEN")
  end

  let!(:ruby_tag) { Tag.create!(name: "Ruby") }
  let!(:rails_tag) { Tag.create!(name: "Rails") }

  let!(:published_post) do
    post = Post.create!(
      title: "Published Post",
      body_markdown: "# Hello World\n\nThis is content.",
      excerpt: "A published post",
      status: :published,
      published_at: 2.days.ago
    )
    post.tags << ruby_tag
    post
  end

  let!(:draft_post) do
    Post.create!(
      title: "Draft Post",
      body_markdown: "# Draft\n\nWork in progress.",
      status: :draft
    )
  end

  describe "GET /api/v1/posts" do
    it "returns 401 without authentication" do
      get "/api/v1/posts"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns all posts" do
      get "/api/v1/posts", headers: api_headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["posts"].length).to eq(2)
      expect(body["meta"]["total_count"]).to eq(2)
    end

    it "returns post attributes" do
      get "/api/v1/posts", headers: api_headers
      post_json = response.parsed_body["posts"].find { |p| p["slug"] == published_post.slug }

      expect(post_json["id"]).to eq(published_post.id)
      expect(post_json["title"]).to eq("Published Post")
      expect(post_json["slug"]).to eq(published_post.slug)
      expect(post_json["excerpt"]).to eq("A published post")
      expect(post_json["status"]).to eq("published")
      expect(post_json["published_at"]).to be_present
      expect(post_json["reading_time"]).to eq(1)
      expect(post_json["tags"]).to eq([ "Ruby" ])
    end

    it "filters by status=published" do
      get "/api/v1/posts", params: { status: "published" }, headers: api_headers
      posts = response.parsed_body["posts"]

      expect(posts.length).to eq(1)
      expect(posts.first["title"]).to eq("Published Post")
    end

    it "filters by status=draft" do
      get "/api/v1/posts", params: { status: "draft" }, headers: api_headers
      posts = response.parsed_body["posts"]

      expect(posts.length).to eq(1)
      expect(posts.first["title"]).to eq("Draft Post")
    end

    it "filters by tag slug" do
      get "/api/v1/posts", params: { tag: "ruby" }, headers: api_headers
      posts = response.parsed_body["posts"]

      expect(posts.length).to eq(1)
      expect(posts.first["title"]).to eq("Published Post")
    end

    it "returns empty when filtering by tag with no posts" do
      get "/api/v1/posts", params: { tag: "rails" }, headers: api_headers
      expect(response.parsed_body["posts"]).to be_empty
    end

    it "searches by title" do
      get "/api/v1/posts", params: { search: "draft" }, headers: api_headers
      posts = response.parsed_body["posts"]

      expect(posts.length).to eq(1)
      expect(posts.first["title"]).to eq("Draft Post")
    end

    it "search is case-insensitive" do
      get "/api/v1/posts", params: { search: "PUBLISHED" }, headers: api_headers
      posts = response.parsed_body["posts"]

      expect(posts.length).to eq(1)
      expect(posts.first["title"]).to eq("Published Post")
    end

    it "paginates results (10 per page)" do
      12.times do |i|
        Post.create!(title: "Bulk Post #{i}", body_markdown: "# Content", status: :draft)
      end

      get "/api/v1/posts", params: { page: 1 }, headers: api_headers
      body = response.parsed_body
      expect(body["posts"].length).to eq(10)
      expect(body["meta"]["total_count"]).to eq(14) # 12 + 2 from let!

      get "/api/v1/posts", params: { page: 2 }, headers: api_headers
      body = response.parsed_body
      expect(body["posts"].length).to eq(4)
    end
  end

  describe "GET /api/v1/posts/:slug" do
    it "returns 401 without authentication" do
      get "/api/v1/posts/#{published_post.slug}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns full post with rendered HTML" do
      get "/api/v1/posts/#{published_post.slug}", headers: api_headers
      expect(response).to have_http_status(:ok)

      post_json = response.parsed_body
      expect(post_json["title"]).to eq("Published Post")
      expect(post_json["body_markdown"]).to include("# Hello World")
      expect(post_json["rendered_body"]).to include("<h1>Hello World</h1>")
      expect(post_json["slug"]).to eq(published_post.slug)
      expect(post_json["reading_time"]).to eq(1)
    end

    it "includes tags" do
      get "/api/v1/posts/#{published_post.slug}", headers: api_headers
      post_json = response.parsed_body

      expect(post_json["tags"].length).to eq(1)
      expect(post_json["tags"].first["name"]).to eq("Ruby")
      expect(post_json["tags"].first["slug"]).to eq("ruby")
    end

    it "includes approved comments" do
      published_post.comments.create!(author_name: "Alice", email: "a@test.com", body: "Great!", status: :approved)
      published_post.comments.create!(author_name: "Spam", email: "s@test.com", body: "Buy stuff", status: :spam)

      get "/api/v1/posts/#{published_post.slug}", headers: api_headers
      post_json = response.parsed_body

      expect(post_json["comments"].length).to eq(2)
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/posts/nonexistent", headers: api_headers
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Not found")
    end
  end

  describe "POST /api/v1/posts" do
    it "returns 401 without authentication" do
      post "/api/v1/posts", params: { post: { title: "New" } }
      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a draft post" do
      expect {
        post "/api/v1/posts", params: {
          post: { title: "New Post", body_markdown: "# Content", excerpt: "Summary" }
        }, headers: api_headers
      }.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      post_json = response.parsed_body
      expect(post_json["title"]).to eq("New Post")
      expect(post_json["status"]).to eq("draft")
      expect(post_json["slug"]).to eq("new-post")
    end

    it "creates a published post and sets published_at" do
      freeze_time do
        post "/api/v1/posts", params: {
          post: { title: "Live Post", body_markdown: "# Content", status: "published" }
        }, headers: api_headers

        expect(response).to have_http_status(:created)
        post_json = response.parsed_body
        expect(post_json["status"]).to eq("published")
        expect(post_json["published_at"]).to eq(Time.current.iso8601(3))
      end
    end

    it "assigns tags" do
      post "/api/v1/posts", params: {
        post: { title: "Tagged Post", body_markdown: "# Content", tag_ids: [ ruby_tag.id, rails_tag.id ] }
      }, headers: api_headers

      expect(response).to have_http_status(:created)
      created_post = Post.find_by(slug: "tagged-post")
      expect(created_post.tags.map(&:name)).to match_array([ "Ruby", "Rails" ])
    end

    it "returns 422 with invalid params" do
      post "/api/v1/posts", params: {
        post: { title: "", body_markdown: "" }
      }, headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/posts/:slug" do
    it "returns 401 without authentication" do
      patch "/api/v1/posts/#{draft_post.slug}", params: { post: { title: "Updated" } }
      expect(response).to have_http_status(:unauthorized)
    end

    it "updates the post" do
      patch "/api/v1/posts/#{draft_post.slug}", params: {
        post: { title: "Updated Title", excerpt: "New excerpt" }
      }, headers: api_headers

      expect(response).to have_http_status(:ok)
      post_json = response.parsed_body
      expect(post_json["title"]).to eq("Updated Title")
      expect(post_json["excerpt"]).to eq("New excerpt")
    end

    it "sets published_at when updating status to published" do
      freeze_time do
        patch "/api/v1/posts/#{draft_post.slug}", params: {
          post: { status: "published" }
        }, headers: api_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["published_at"]).to eq(Time.current.iso8601(3))
      end
    end

    it "returns 422 with invalid params" do
      patch "/api/v1/posts/#{draft_post.slug}", params: {
        post: { title: "" }
      }, headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "returns 404 for unknown slug" do
      patch "/api/v1/posts/nonexistent", params: { post: { title: "X" } }, headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/posts/:slug" do
    it "returns 401 without authentication" do
      delete "/api/v1/posts/#{draft_post.slug}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "deletes the post" do
      expect {
        delete "/api/v1/posts/#{draft_post.slug}", headers: api_headers
      }.to change(Post, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for unknown slug" do
      delete "/api/v1/posts/nonexistent", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/posts/:slug/publish" do
    it "returns 401 without authentication" do
      post "/api/v1/posts/#{draft_post.slug}/publish"
      expect(response).to have_http_status(:unauthorized)
    end

    it "publishes a draft post" do
      freeze_time do
        post "/api/v1/posts/#{draft_post.slug}/publish", headers: api_headers

        expect(response).to have_http_status(:ok)
        post_json = response.parsed_body
        expect(post_json["status"]).to eq("published")
        expect(post_json["published_at"]).to eq(Time.current.iso8601(3))
      end
    end

    it "returns 422 if already published" do
      post "/api/v1/posts/#{published_post.slug}/publish", headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("already published")
    end

    it "returns 404 for unknown slug" do
      post "/api/v1/posts/nonexistent/publish", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
