class MarkdownRenderer
  EXTENSIONS = {
    autolink: true,
    fenced_code_blocks: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    lax_spacing: true
  }.freeze

  class HTMLRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      %(<pre><code class="language-#{language || 'plaintext'}">#{ERB::Util.html_escape(code)}</code></pre>)
    end
  end

  class HighlightedRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
      formatter = Rouge::Formatters::HTMLInline.new(Rouge::Theme.find("base16.solarized"))
      formatted = formatter.format(lexer.lex(code))
      %(<pre class="highlight"><code>#{formatted}</code></pre>)
    end
  end

  def self.render(markdown)
    return "" if markdown.blank?

    renderer = HTMLRenderer.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" })
    Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(markdown).html_safe
  end

  def self.render_with_highlighting(markdown)
    return "" if markdown.blank?

    renderer = HighlightedRenderer.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" })
    Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(markdown).html_safe
  end
end
