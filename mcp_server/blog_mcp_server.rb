#!/usr/bin/env ruby
# frozen_string_literal: true

require "mcp"
require "net/http"
require "json"
require "uri"

# HTTP client for the blog API
class BlogApiClient
  def initialize
    @base_url = ENV.fetch("BLOG_URL", "https://blog.estebansoto.dev")
    @token = ENV.fetch("BLOG_API_TOKEN") { raise "BLOG_API_TOKEN environment variable is required" }
  end

  def get(path, params = {})
    uri = URI("#{@base_url}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    request = Net::HTTP::Get.new(uri)
    execute(uri, request)
  end

  def post(path, body = {})
    uri = URI("#{@base_url}#{path}")
    request = Net::HTTP::Post.new(uri)
    request.body = body.to_json
    request["Content-Type"] = "application/json"
    execute(uri, request)
  end

  def patch(path, body = {})
    uri = URI("#{@base_url}#{path}")
    request = Net::HTTP::Patch.new(uri)
    request.body = body.to_json
    request["Content-Type"] = "application/json"
    execute(uri, request)
  end

  def delete(path)
    uri = URI("#{@base_url}#{path}")
    request = Net::HTTP::Delete.new(uri)
    execute(uri, request)
  end

  private

  def execute(uri, request)
    request["Authorization"] = "Bearer #{@token}"
    request["Accept"] = "application/json"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30

    response = http.request(request)

    case response.code.to_i
    when 200, 201
      JSON.parse(response.body)
    when 204
      { "status" => "success" }
    when 401
      { "error" => "Unauthorized — check BLOG_API_TOKEN" }
    when 404
      { "error" => "Not found" }
    when 422
      JSON.parse(response.body)
    when 429
      { "error" => "Rate limit exceeded — try again later" }
    else
      { "error" => "HTTP #{response.code}: #{response.body}" }
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    { "error" => "Request timed out: #{e.message}" }
  rescue StandardError => e
    { "error" => "Request failed: #{e.message}" }
  end
end

CLIENT = BlogApiClient.new

# --- Posts Tools ---

class ListPosts < MCP::Tool
  description "List blog posts with optional filters for status, tag, search, and pagination"

  input_schema(
    properties: {
      status: { type: "string", enum: %w[draft published], description: "Filter by post status" },
      tag: { type: "string", description: "Filter by tag slug" },
      search: { type: "string", description: "Search posts by title" },
      page: { type: "integer", description: "Page number (default: 1, 10 per page)" }
    }
  )

  def self.call(server_context:, **params)
    result = CLIENT.get("/api/v1/posts", params.compact)
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class GetPost < MCP::Tool
  description "Get a single blog post by slug, including rendered HTML, comments, and tags"

  input_schema(
    properties: {
      slug: { type: "string", description: "Post slug" }
    },
    required: [ "slug" ]
  )

  def self.call(slug:, server_context:)
    result = CLIENT.get("/api/v1/posts/#{slug}")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class CreatePost < MCP::Tool
  description "Create a new blog post (defaults to draft status)"

  input_schema(
    properties: {
      title: { type: "string", description: "Post title" },
      body_markdown: { type: "string", description: "Post content in Markdown" },
      excerpt: { type: "string", description: "Short excerpt/summary" },
      status: { type: "string", enum: %w[draft published], description: "Post status (default: draft)" },
      tag_ids: { type: "array", items: { type: "integer" }, description: "Array of tag IDs to assign" }
    },
    required: %w[title body_markdown]
  )

  def self.call(server_context:, **params)
    result = CLIENT.post("/api/v1/posts", { post: params.compact })
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class UpdatePost < MCP::Tool
  description "Update an existing blog post by slug"

  input_schema(
    properties: {
      slug: { type: "string", description: "Post slug to update" },
      title: { type: "string", description: "New title" },
      body_markdown: { type: "string", description: "New content in Markdown" },
      excerpt: { type: "string", description: "New excerpt" },
      status: { type: "string", enum: %w[draft published], description: "New status" },
      tag_ids: { type: "array", items: { type: "integer" }, description: "New tag IDs" }
    },
    required: [ "slug" ]
  )

  def self.call(slug:, server_context:, **params)
    result = CLIENT.patch("/api/v1/posts/#{slug}", { post: params.compact })
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class DeletePost < MCP::Tool
  description "Delete a blog post by slug"

  input_schema(
    properties: {
      slug: { type: "string", description: "Post slug to delete" }
    },
    required: [ "slug" ]
  )

  def self.call(slug:, server_context:)
    result = CLIENT.delete("/api/v1/posts/#{slug}")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class PublishPost < MCP::Tool
  description "Publish a draft blog post (sets status to published and published_at to now)"

  input_schema(
    properties: {
      slug: { type: "string", description: "Post slug to publish" }
    },
    required: [ "slug" ]
  )

  def self.call(slug:, server_context:)
    result = CLIENT.post("/api/v1/posts/#{slug}/publish")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class PreviewMarkdown < MCP::Tool
  description "Preview markdown content rendered as HTML with syntax highlighting"

  input_schema(
    properties: {
      markdown: { type: "string", description: "Markdown content to preview" }
    },
    required: [ "markdown" ]
  )

  def self.call(markdown:, server_context:)
    result = CLIENT.post("/api/v1/preview", { markdown: markdown })
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

# --- Comments Tools ---

class ListComments < MCP::Tool
  description "List blog comments with optional filters for status and post"

  input_schema(
    properties: {
      status: { type: "string", enum: %w[pending approved spam], description: "Filter by status (default: pending)" },
      post_slug: { type: "string", description: "Filter by post slug" },
      page: { type: "integer", description: "Page number (default: 1, 25 per page)" }
    }
  )

  def self.call(server_context:, **params)
    result = CLIENT.get("/api/v1/comments", params.compact)
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class ApproveComment < MCP::Tool
  description "Approve a pending blog comment"

  input_schema(
    properties: {
      id: { type: "integer", description: "Comment ID to approve" }
    },
    required: [ "id" ]
  )

  def self.call(id:, server_context:)
    result = CLIENT.patch("/api/v1/comments/#{id}/approve")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class SpamComment < MCP::Tool
  description "Mark a blog comment as spam"

  input_schema(
    properties: {
      id: { type: "integer", description: "Comment ID to mark as spam" }
    },
    required: [ "id" ]
  )

  def self.call(id:, server_context:)
    result = CLIENT.patch("/api/v1/comments/#{id}/spam")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class DeleteComment < MCP::Tool
  description "Delete a blog comment"

  input_schema(
    properties: {
      id: { type: "integer", description: "Comment ID to delete" }
    },
    required: [ "id" ]
  )

  def self.call(id:, server_context:)
    result = CLIENT.delete("/api/v1/comments/#{id}")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

# --- Tags Tools ---

class ListTags < MCP::Tool
  description "List all blog tags with post counts"

  input_schema(
    properties: {
      _placeholder: { type: "string", description: "No parameters needed" }
    }
  )

  def self.call(server_context:, **_params)
    result = CLIENT.get("/api/v1/tags")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class CreateTag < MCP::Tool
  description "Create a new blog tag (slug is auto-generated from name)"

  input_schema(
    properties: {
      name: { type: "string", description: "Tag name" }
    },
    required: [ "name" ]
  )

  def self.call(name:, server_context:)
    result = CLIENT.post("/api/v1/tags", { tag: { name: name } })
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class UpdateTag < MCP::Tool
  description "Update a blog tag name"

  input_schema(
    properties: {
      id: { type: "integer", description: "Tag ID to update" },
      name: { type: "string", description: "New tag name" }
    },
    required: %w[id name]
  )

  def self.call(id:, name:, server_context:)
    result = CLIENT.patch("/api/v1/tags/#{id}", { tag: { name: name } })
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

class DeleteTag < MCP::Tool
  description "Delete a blog tag"

  input_schema(
    properties: {
      id: { type: "integer", description: "Tag ID to delete" }
    },
    required: [ "id" ]
  )

  def self.call(id:, server_context:)
    result = CLIENT.delete("/api/v1/tags/#{id}")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

# --- Stats Tool ---

class SiteStats < MCP::Tool
  description "Get blog dashboard stats: total posts, published, drafts, pending comments, and tag count"

  input_schema(
    properties: {
      _placeholder: { type: "string", description: "No parameters needed" }
    }
  )

  def self.call(server_context:, **_params)
    result = CLIENT.get("/api/v1/stats")
    MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ])
  end
end

# --- Start Server ---

server = MCP::Server.new(
  name: "blog-mcp-server",
  version: "1.0.0",
  tools: [
    ListPosts, GetPost, CreatePost, UpdatePost, DeletePost, PublishPost, PreviewMarkdown,
    ListComments, ApproveComment, SpamComment, DeleteComment,
    ListTags, CreateTag, UpdateTag, DeleteTag,
    SiteStats
  ]
)

transport = MCP::Server::Transports::StdioTransport.new(server)
transport.open
