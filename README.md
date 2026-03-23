# Personal Blog

A personal tech blog built with Rails 8, hosted on Render.

**Live:** [blog.estebansoto.dev](https://blog.estebansoto.dev)

## Stack

- **Framework:** Rails 8.1.2, Ruby 3.4
- **Database:** PostgreSQL
- **Frontend:** Hotwire (Turbo + Stimulus), Propshaft
- **Styling:** Tailwind CSS with dark dev aesthetic
- **Hosting:** Render (Docker)
- **Markdown:** Redcarpet + Rouge syntax highlighting

## Features

- Markdown editor with live preview and toolbar
- RSS feed at `/feed`
- XML sitemap at `/sitemap.xml`
- SEO: JSON-LD structured data (WebSite, BlogPosting, Person, BreadcrumbList)
- OG/Twitter meta tags, canonical URLs
- Comments with honeypot spam protection
- Tag-based content organization
- Reading time estimates
- Admin dashboard with post/comment/tag management

## API

RESTful JSON API under `/api/v1/` with bearer token authentication.

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/stats` | Dashboard stats |
| `GET /api/v1/posts` | List posts (filters: status, tag, search, page) |
| `GET /api/v1/posts/:slug` | Get post with rendered HTML, comments, tags |
| `POST /api/v1/posts` | Create post |
| `PATCH /api/v1/posts/:slug` | Update post |
| `DELETE /api/v1/posts/:slug` | Delete post |
| `POST /api/v1/posts/:slug/publish` | Publish draft |
| `POST /api/v1/preview` | Preview markdown |
| `GET /api/v1/comments` | List comments (filter by status, post) |
| `PATCH /api/v1/comments/:id/approve` | Approve comment |
| `PATCH /api/v1/comments/:id/spam` | Mark as spam |
| `DELETE /api/v1/comments/:id` | Delete comment |
| `GET /api/v1/tags` | List tags with post counts |
| `POST /api/v1/tags` | Create tag |
| `PATCH /api/v1/tags/:id` | Update tag |
| `DELETE /api/v1/tags/:id` | Delete tag |

## MCP Server

A local MCP server connects Claude Code to the blog API, enabling AI-powered content management with 16 tools.

See [docs/mcp-server.md](docs/mcp-server.md) for setup and usage.

```
Claude Code ──stdio──> MCP Server (Ruby) ──HTTPS──> Blog API (Render)
```

## Development

```bash
bin/setup
bin/dev
```

## Tests

```bash
bundle exec rspec
```

## Deployment

Deployed automatically via Render on push to `main`. Uses Docker (see `Dockerfile`).
