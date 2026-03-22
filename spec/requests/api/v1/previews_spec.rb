require "rails_helper"

RSpec.describe "API V1 Previews", type: :request do
  around do |example|
    original = ENV["BLOG_API_TOKEN"]
    ENV["BLOG_API_TOKEN"] = "test-api-token"
    example.run
  ensure
    original ? ENV["BLOG_API_TOKEN"] = original : ENV.delete("BLOG_API_TOKEN")
  end

  describe "POST /api/v1/preview" do
    it "returns 401 without authentication" do
      post "/api/v1/preview", params: { markdown: "# Hello" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "renders markdown to HTML" do
      post "/api/v1/preview", params: { markdown: "# Hello World" }, headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["html"]).to include("<h1>Hello World</h1>")
    end

    it "renders code blocks with syntax highlighting" do
      markdown = "```ruby\nputs 'hello'\n```"
      post "/api/v1/preview", params: { markdown: markdown }, headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["html"]).to include("highlight")
    end

    it "returns 422 for blank markdown" do
      post "/api/v1/preview", params: { markdown: "" }, headers: api_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end

    it "returns 422 when markdown param is missing" do
      post "/api/v1/preview", headers: api_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
