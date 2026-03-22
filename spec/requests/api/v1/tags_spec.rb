require "rails_helper"

RSpec.describe "API V1 Tags", type: :request do
  around do |example|
    original = ENV["BLOG_API_TOKEN"]
    ENV["BLOG_API_TOKEN"] = "test-api-token"
    example.run
  ensure
    original ? ENV["BLOG_API_TOKEN"] = original : ENV.delete("BLOG_API_TOKEN")
  end

  describe "authentication" do
    it "returns 401 for GET /api/v1/tags without auth" do
      get "/api/v1/tags"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for POST /api/v1/tags without auth" do
      post "/api/v1/tags", params: { tag: { name: "Ruby" } }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for PATCH /api/v1/tags/:id without auth" do
      tag = Tag.create!(name: "Ruby")
      patch "/api/v1/tags/#{tag.id}", params: { tag: { name: "Updated" } }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for DELETE /api/v1/tags/:id without auth" do
      tag = Tag.create!(name: "Ruby")
      delete "/api/v1/tags/#{tag.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/tags" do
    it "returns tags ordered by name with post counts" do
      Tag.create!(name: "Zsh")
      Tag.create!(name: "Algorithms")
      Tag.create!(name: "Ruby")

      get "/api/v1/tags", headers: api_headers

      expect(response).to have_http_status(:ok)
      tags = response.parsed_body
      expect(tags.length).to eq(3)
      expect(tags.map { |t| t["name"] }).to eq(%w[Algorithms Ruby Zsh])
      expect(tags.first).to include("id", "name", "slug", "posts_count")
    end

    it "returns correct post counts" do
      ruby = Tag.create!(name: "Ruby")
      rails = Tag.create!(name: "Rails")
      orphan = Tag.create!(name: "Orphan")

      post1 = Post.create!(title: "Post 1", body_markdown: "# Content", status: :published, published_at: 1.day.ago)
      post2 = Post.create!(title: "Post 2", body_markdown: "# Content", status: :published, published_at: 2.days.ago)
      post3 = Post.create!(title: "Post 3", body_markdown: "# Content", status: :draft)

      PostTag.create!(post: post1, tag: ruby)
      PostTag.create!(post: post2, tag: ruby)
      PostTag.create!(post: post3, tag: ruby)
      PostTag.create!(post: post1, tag: rails)

      get "/api/v1/tags", headers: api_headers

      tags = response.parsed_body
      ruby_tag = tags.find { |t| t["name"] == "Ruby" }
      rails_tag = tags.find { |t| t["name"] == "Rails" }
      orphan_tag = tags.find { |t| t["name"] == "Orphan" }

      expect(ruby_tag["posts_count"]).to eq(3)
      expect(rails_tag["posts_count"]).to eq(1)
      expect(orphan_tag["posts_count"]).to eq(0)
    end

    it "returns empty array when no tags exist" do
      get "/api/v1/tags", headers: api_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "POST /api/v1/tags" do
    it "creates a tag with auto-generated slug" do
      post "/api/v1/tags", params: { tag: { name: "Ruby on Rails" } }, headers: api_headers

      expect(response).to have_http_status(:created)
      tag = response.parsed_body
      expect(tag["name"]).to eq("Ruby on Rails")
      expect(tag["slug"]).to eq("ruby-on-rails")
      expect(tag["id"]).to be_present
    end

    it "returns 422 for duplicate name" do
      Tag.create!(name: "Ruby")

      post "/api/v1/tags", params: { tag: { name: "Ruby" } }, headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Name has already been taken")
    end

    it "returns 422 for blank name" do
      post "/api/v1/tags", params: { tag: { name: "" } }, headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/tags/:id" do
    it "updates tag name" do
      tag = Tag.create!(name: "Rubi")

      patch "/api/v1/tags/#{tag.id}", params: { tag: { name: "Ruby" } }, headers: api_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["name"]).to eq("Ruby")
      expect(tag.reload.name).to eq("Ruby")
    end

    it "returns 422 for invalid update" do
      Tag.create!(name: "Ruby")
      tag = Tag.create!(name: "Rails")

      patch "/api/v1/tags/#{tag.id}", params: { tag: { name: "Ruby" } }, headers: api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Name has already been taken")
    end

    it "returns 404 for unknown ID" do
      patch "/api/v1/tags/999999", params: { tag: { name: "Ruby" } }, headers: api_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/tags/:id" do
    it "returns 204 and deletes the tag" do
      tag = Tag.create!(name: "Ruby")

      delete "/api/v1/tags/#{tag.id}", headers: api_headers

      expect(response).to have_http_status(:no_content)
      expect(Tag.find_by(id: tag.id)).to be_nil
    end

    it "returns 404 for unknown ID" do
      delete "/api/v1/tags/999999", headers: api_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
