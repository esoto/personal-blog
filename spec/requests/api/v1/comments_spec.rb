require "rails_helper"

RSpec.describe "API V1 Comments", type: :request do
  around do |example|
    original = ENV["BLOG_API_TOKEN"]
    ENV["BLOG_API_TOKEN"] = "test-api-token"
    example.run
  ensure
    original ? ENV["BLOG_API_TOKEN"] = original : ENV.delete("BLOG_API_TOKEN")
  end

  let(:post_record) do
    Post.create!(title: "Test Post", body_markdown: "# Content", status: :published, published_at: 1.day.ago)
  end

  let!(:pending_comment) do
    post_record.comments.create!(author_name: "Alice", email: "alice@test.com", body: "Pending comment", status: :pending)
  end

  let!(:approved_comment) do
    post_record.comments.create!(author_name: "Bob", email: "bob@test.com", body: "Approved comment", status: :approved)
  end

  let!(:spam_comment) do
    post_record.comments.create!(author_name: "Carol", email: "carol@test.com", body: "Spam comment", status: :spam)
  end

  describe "authentication" do
    it "returns 401 for GET /api/v1/comments without auth" do
      get "/api/v1/comments"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for PATCH /api/v1/comments/:id/approve without auth" do
      patch "/api/v1/comments/#{pending_comment.id}/approve"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for PATCH /api/v1/comments/:id/spam without auth" do
      patch "/api/v1/comments/#{pending_comment.id}/spam"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for DELETE /api/v1/comments/:id without auth" do
      delete "/api/v1/comments/#{pending_comment.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/comments" do
    it "defaults to pending status filter" do
      get "/api/v1/comments", headers: api_headers

      expect(response).to have_http_status(:ok)
      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["author_name"]).to eq("Alice")
    end

    it "filters by status param pending" do
      get "/api/v1/comments", params: { status: "pending" }, headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["status"]).to eq("pending")
    end

    it "filters by status param approved" do
      get "/api/v1/comments", params: { status: "approved" }, headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["status"]).to eq("approved")
    end

    it "filters by status param spam" do
      get "/api/v1/comments", params: { status: "spam" }, headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["status"]).to eq("spam")
    end

    it "ignores invalid status params and defaults to pending" do
      get "/api/v1/comments", params: { status: "invalid" }, headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["status"]).to eq("pending")
    end

    it "filters by post_slug" do
      other_post = Post.create!(title: "Other Post", body_markdown: "# Other", status: :published, published_at: 1.day.ago)
      other_post.comments.create!(author_name: "Dave", email: "dave@test.com", body: "Other pending", status: :pending)

      get "/api/v1/comments", params: { post_slug: post_record.slug }, headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(1)
      expect(comments.first["author_name"]).to eq("Alice")
    end

    it "returns comment with post_title and post_slug" do
      get "/api/v1/comments", headers: api_headers

      comment = response.parsed_body["comments"].first
      expect(comment["post_title"]).to eq("Test Post")
      expect(comment["post_slug"]).to eq(post_record.slug)
    end

    it "does not expose comment email in response" do
      get "/api/v1/comments", headers: api_headers

      comment = response.parsed_body["comments"].first
      expect(comment).not_to have_key("email")
    end

    it "orders comments by most recent first" do
      newer_comment = post_record.comments.create!(
        author_name: "Eve", email: "eve@test.com", body: "Newer pending", status: :pending,
        created_at: 1.minute.from_now
      )

      get "/api/v1/comments", headers: api_headers

      comments = response.parsed_body["comments"]
      expect(comments.length).to eq(2)
      expect(comments.first["id"]).to eq(newer_comment.id)
    end
  end

  describe "PATCH /api/v1/comments/:id/approve" do
    it "approves a pending comment" do
      patch "/api/v1/comments/#{pending_comment.id}/approve", headers: api_headers

      expect(response).to have_http_status(:ok)
      comment = response.parsed_body
      expect(comment["status"]).to eq("approved")
      expect(pending_comment.reload).to be_approved
    end

    it "returns 404 for unknown comment ID" do
      patch "/api/v1/comments/999999/approve", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/comments/:id/spam" do
    it "marks a comment as spam" do
      patch "/api/v1/comments/#{pending_comment.id}/spam", headers: api_headers

      expect(response).to have_http_status(:ok)
      comment = response.parsed_body
      expect(comment["status"]).to eq("spam")
      expect(pending_comment.reload).to be_spam
    end

    it "returns 404 for unknown comment ID" do
      patch "/api/v1/comments/999999/spam", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    it "deletes the comment and returns 204" do
      delete "/api/v1/comments/#{spam_comment.id}", headers: api_headers

      expect(response).to have_http_status(:no_content)
      expect(Comment.find_by(id: spam_comment.id)).to be_nil
    end

    it "returns 404 for unknown comment ID" do
      delete "/api/v1/comments/999999", headers: api_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
