# Blog MCP Server

Local MCP server that connects Claude Code to the blog at blog.estebansoto.dev.

## Setup

```bash
cd mcp_server
bundle install
```

## Configuration

Set these environment variables:

```bash
export BLOG_URL="https://blog.estebansoto.dev"  # optional, this is the default
export BLOG_API_TOKEN="your-token-here"          # required
```

## Testing

```bash
npx @modelcontextprotocol/inspector ruby blog_mcp_server.rb
```

## Available Tools (16)

**Posts:** list_posts, get_post, create_post, update_post, delete_post, publish_post, preview_markdown
**Comments:** list_comments, approve_comment, spam_comment, delete_comment
**Tags:** list_tags, create_tag, update_tag, delete_tag
**Stats:** site_stats
