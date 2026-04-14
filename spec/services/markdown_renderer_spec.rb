require "rails_helper"

RSpec.describe MarkdownRenderer do
  describe ".render" do
    it "converts markdown headings to HTML" do
      result = described_class.render("# Hello")
      expect(result).to include("<h1>Hello</h1>")
    end

    it "converts bold text" do
      result = described_class.render("**bold**")
      expect(result).to include("<strong>bold</strong>")
    end

    it "converts code blocks to pre/code tags" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include("<pre>")
      expect(result).to include("<code")
    end

    it "converts inline code" do
      result = described_class.render("Use `foo` here")
      expect(result).to include("<code>foo</code>")
    end

    it "converts links" do
      result = described_class.render("[click](https://example.com)")
      expect(result).to include('<a href="https://example.com"')
    end

    it "returns empty string for nil input" do
      expect(described_class.render(nil)).to eq("")
    end

    it "returns empty string for blank input" do
      expect(described_class.render("")).to eq("")
    end

    it "enables tables" do
      md = "| A | B |\n|---|---|\n| 1 | 2 |"
      result = described_class.render(md)
      expect(result).to include("<table>")
    end

    it "enables autolinks" do
      result = described_class.render("Visit https://example.com")
      expect(result).to include('<a href="https://example.com"')
    end

    it "strips javascript: URIs from markdown links" do
      result = described_class.render("[click](javascript:alert(1))")
      expect(result).not_to include("javascript:")
    end

    it "strips data: URIs from markdown links" do
      result = described_class.render("[click](data:text/html,<script>alert(1)</script>)")
      expect(result).not_to include("data:")
    end

    it "preserves legitimate https links" do
      result = described_class.render("[click](https://example.com)")
      expect(result).to include('href="https://example.com"')
    end
  end

  describe ".render — heading anchors" do
    it "emits an id on h2 headings derived from the text" do
      result = described_class.render("## Getting Started")
      expect(result).to include('<h2 id="getting-started">Getting Started</h2>')
    end

    it "emits an id on h3 headings derived from the text" do
      result = described_class.render("### Install Dependencies")
      expect(result).to include('<h3 id="install-dependencies">Install Dependencies</h3>')
    end

    it "does not emit an id on h1 headings" do
      result = described_class.render("# Top Level")
      expect(result).to include("<h1>Top Level</h1>")
      expect(result).not_to match(/<h1[^>]*id=/)
    end

    it "does not emit an id on h4+ headings" do
      result = described_class.render("#### Deep heading")
      expect(result).to include("<h4>Deep heading</h4>")
      expect(result).not_to match(/<h4[^>]*id=/)
    end

    it "disambiguates colliding slugs with a numeric suffix" do
      md = "## Setup\n\nBody.\n\n## Setup\n\nMore body."
      result = described_class.render(md)
      expect(result).to include('<h2 id="setup">Setup</h2>')
      expect(result).to include('<h2 id="setup-1">Setup</h2>')
    end

    it "falls back to 'section' when a heading parameterizes to empty" do
      result = described_class.render("## !!!")
      expect(result).to include('<h2 id="section">')
    end
  end

  describe ".render — enhanced code block structure" do
    it "wraps code blocks in a figure with the clipboard controller" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<figure class="code-block"')
      expect(result).to include('data-controller="clipboard"')
    end

    it "includes a figcaption with language label" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<figcaption class="code-block-header">')
      expect(result).to include('<span class="code-block-language">ruby</span>')
    end

    it "includes a copy button wired to the clipboard controller" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('class="code-block-copy"')
      expect(result).to include('data-clipboard-target="button"')
      expect(result).to include('data-action="click->clipboard#copy"')
    end

    it "includes the copy icon as inline SVG" do
      result = described_class.render("```ruby\nputs 'hi'\n```")
      expect(result).to include('<svg class="code-block-copy-icon"')
    end

    it "falls back to plaintext when language is omitted" do
      result = described_class.render("```\nplain\n```")
      expect(result).to include('<span class="code-block-language">plaintext</span>')
    end

    it "HTML-escapes code contents to prevent injection" do
      result = described_class.render("```html\n<script>alert(1)</script>\n```")
      expect(result).not_to include("<script>alert(1)</script>")
      expect(result).to include("&lt;script&gt;")
    end
  end

  describe ".render — callouts" do
    %w[info tip warning danger].each do |type|
      it "renders a :::#{type} callout as an aside with the callout-#{type} class" do
        md = ":::#{type}\nThis is a #{type} body.\n:::"
        result = described_class.render(md)
        expect(result).to include("<aside")
        expect(result).to include("callout-#{type}")
        expect(result).to include("This is a #{type} body.")
      end

      it "marks the #{type} callout with role=note for accessibility" do
        md = ":::#{type}\nContent\n:::"
        result = described_class.render(md)
        expect(result).to include('role="note"')
      end

      it "includes an inline SVG icon in the #{type} callout" do
        md = ":::#{type}\nContent\n:::"
        result = described_class.render(md)
        expect(result).to include('class="callout-icon"')
      end
    end

    it "renders markdown inside the callout body (bold/links/inline code)" do
      md = <<~MD
        :::tip
        Use **bold** and `code` and [link](https://example.com).
        :::
      MD
      result = described_class.render(md)
      expect(result).to include("<strong>bold</strong>")
      expect(result).to include("<code>code</code>")
      expect(result).to include('href="https://example.com"')
    end

    it "supports multiple callouts in one document" do
      md = <<~MD
        :::info
        First
        :::

        Some paragraph.

        :::warning
        Second
        :::
      MD
      result = described_class.render(md)
      expect(result).to include("callout-info")
      expect(result).to include("callout-warning")
      expect(result).to include("First")
      expect(result).to include("Second")
      expect(result).to include("Some paragraph")
    end

    it "leaves unrecognized callout types as raw text (not transformed)" do
      md = ":::bogus\nContent\n:::"
      result = described_class.render(md)
      expect(result).not_to include("callout-bogus")
      expect(result).not_to include("<aside")
      expect(result).to include(":::bogus")
      expect(result).to include("Content")
    end

    it "renders a fenced code block inside a callout body" do
      md = ":::tip\nUse this snippet:\n\n```ruby\nputs 'hi'\n```\n:::"
      result = described_class.render(md)
      expect(result).to include("callout-tip")
      expect(result).to include('<figure class="code-block"')
      expect(result).to include("puts")
    end

    it "does not merge two adjacent callouts into one (non-greedy)" do
      md = ":::info\nA\n:::\n\n:::warning\nB\n:::"
      result = described_class.render(md)
      expect(result.scan("<aside").length).to eq(2)
      expect(result).to include("callout-info")
      expect(result).to include("callout-warning")
    end

    it "leaves an unclosed callout fence as raw text (no crash, no aside)" do
      md = ":::tip\nOrphan body with no closing fence"
      result = described_class.render(md)
      expect(result).not_to include("<aside")
      expect(result).to include("Orphan body")
    end

    it "does NOT rewrite ::: inside a fenced code block" do
      md = "```markdown\n:::tip\nNot a real callout\n:::\n```"
      result = described_class.render(md)
      expect(result).not_to include("<aside")
      expect(result).not_to include("callout-tip")
      # The literal :::tip text should appear in the code block
      expect(result).to include(":::tip")
    end
  end

  describe ".render — sanitizer defense (filter_html is off)" do
    it "strips raw <script> tags in prose (inner text passes through as text node, which is safe)" do
      # Rails::HTML5::SafeListSanitizer operates in "strip" mode — it removes
      # disallowed tags but keeps their inner text as text nodes. The text
      # "alert(1)" becomes a harmless string in a <p>, not executable JS.
      result = described_class.render("Hello <script>alert(1)</script> world")
      expect(result).not_to include("<script")
      expect(result).not_to include("</script")
      expect(result).to include("Hello")
      expect(result).to include("world")
    end

    it "strips on* event attributes from allowed tags" do
      result = described_class.render('<a href="/x" onclick="alert(1)">click</a>')
      expect(result).to include('href="/x"')
      expect(result).not_to include("onclick")
    end

    it "strips disallowed tags like <iframe> and <style>" do
      result = described_class.render("<iframe src='x'></iframe><style>body{}</style>Hello")
      expect(result).not_to include("<iframe")
      expect(result).not_to include("<style")
      expect(result).to include("Hello")
    end

    it "strips javascript: in href attributes even without filter_html" do
      result = described_class.render('<a href="javascript:alert(1)">click</a>')
      expect(result).not_to include("javascript:")
    end
  end

  describe ".render_with_highlighting" do
    it "wraps highlighted code in the shared figure chrome" do
      result = described_class.render_with_highlighting("```ruby\nputs 'hi'\n```")
      expect(result).to include('<figure class="code-block"')
      expect(result).to include('data-controller="clipboard"')
      expect(result).to include('<span class="code-block-language">ruby</span>')
    end

    it "syntax highlights code blocks with inline Rouge styles" do
      result = described_class.render_with_highlighting("```ruby\nputs 'hi'\n```")
      # Rouge HTMLInline formatter emits <span style="..."> tokens
      expect(result).to match(/<span style="[^"]+">/)
    end

    it "falls back to plain code for unknown languages" do
      result = described_class.render_with_highlighting("```\nplain code\n```")
      expect(result).to include('<span class="code-block-language">plaintext</span>')
      expect(result).to include("plain code")
    end

    it "strips javascript: URIs in highlighted renderer" do
      result = described_class.render_with_highlighting("[click](javascript:alert(1))")
      expect(result).not_to include("javascript:")
    end
  end
end
