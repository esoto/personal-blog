# Blog MCP Server

## Architecture

```
Claude Code ──stdio──> MCP Server (local Ruby) ──HTTPS──> Rails API (Render)
                       mcp_server/                        Api::V1::*Controller
                       Official mcp gem                   Bearer token auth
```

The MCP server runs locally on your machine and communicates with the blog's API over HTTPS. It uses the official `mcp` Ruby gem with stdio transport.

## Setup

### 1. Install dependencies

```bash
cd mcp_server
bundle install
```

### 2. Set environment variables

```bash
# Add to your .zshrc or .envrc
export BLOG_API_TOKEN="your-token-here"
export BLOG_URL="https://blog.estebansoto.dev"  # optional, this is the default
```

The `BLOG_API_TOKEN` must match the token set on Render.

### 3. Register in Claude Code

Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "blog": {
      "command": "bash",
      "args": ["-c", "cd /Users/esoto/development/personal_blog/mcp_server && bundle exec ruby blog_mcp_server.rb"],
      "env": {
        "BLOG_API_TOKEN": "${BLOG_API_TOKEN}"
      }
    }
  }
}
```

### 4. Verify

```bash
npx @modelcontextprotocol/inspector ruby mcp_server/blog_mcp_server.rb
```

## Available Tools (16)

### Posts (7)

| Tool | Description |
|------|-------------|
| `list_posts` | List posts with filters (status, tag, search, page) |
| `get_post` | Get single post by slug with rendered HTML, comments, tags |
| `create_post` | Create new post (defaults to draft) |
| `update_post` | Update existing post by slug |
| `delete_post` | Delete post by slug |
| `publish_post` | Publish a draft (sets published_at) |
| `preview_markdown` | Render markdown to HTML with syntax highlighting |

### Comments (4)

| Tool | Description |
|------|-------------|
| `list_comments` | List comments filtered by status (default: pending) and post |
| `approve_comment` | Approve a pending comment |
| `spam_comment` | Mark comment as spam |
| `delete_comment` | Delete a comment |

### Tags (4)

| Tool | Description |
|------|-------------|
| `list_tags` | List all tags with post counts |
| `create_tag` | Create tag (slug auto-generated) |
| `update_tag` | Update tag name |
| `delete_tag` | Delete tag |

### Stats (1)

| Tool | Description |
|------|-------------|
| `site_stats` | Dashboard: total/published/draft posts, pending comments, tag count |

## Security

- Bearer token authentication on all API endpoints
- Token compared with `ActiveSupport::SecurityUtils.secure_compare` (timing-safe)
- API rate limited to 60 requests per minute
- Comment emails excluded from API responses (PII protection)
- `ActionController::API` base — no session/cookie exposure

## API Endpoints

All under `/api/v1/`, requiring `Authorization: Bearer <token>` header.

```
GET    /api/v1/stats
GET    /api/v1/posts
GET    /api/v1/posts/:slug
POST   /api/v1/posts
PATCH  /api/v1/posts/:slug
DELETE /api/v1/posts/:slug
POST   /api/v1/posts/:slug/publish
POST   /api/v1/preview
GET    /api/v1/comments
PATCH  /api/v1/comments/:id/approve
PATCH  /api/v1/comments/:id/spam
DELETE /api/v1/comments/:id
GET    /api/v1/tags
POST   /api/v1/tags
PATCH  /api/v1/tags/:id
DELETE /api/v1/tags/:id
```

## Troubleshooting

**Server won't start:** Check `BLOG_API_TOKEN` is set. Run `echo $BLOG_API_TOKEN`.

**401 errors:** Verify token matches what's set on Render. Check with:
```bash
curl -H "Authorization: Bearer $BLOG_API_TOKEN" https://blog.estebansoto.dev/api/v1/stats
```

**Connection errors:** Verify the blog is running on Render. Check `BLOG_URL` if using a custom domain.
