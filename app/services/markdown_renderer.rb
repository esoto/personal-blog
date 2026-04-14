class MarkdownRenderer
  EXTENSIONS = {
    autolink: true,
    fenced_code_blocks: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    lax_spacing: true
  }.freeze

  # Tags allowed after sanitization. Blog posts are admin-authored content,
  # so we trust them to include richer HTML than user-submitted content would.
  # The sanitizer is still the final line of defense and will strip anything
  # not in this list.
  ALLOWED_TAGS = %w[
    p br h1 h2 h3 h4 h5 h6 ul ol li a img pre code
    em strong blockquote table thead tbody tr th td del hr span div
    figure figcaption aside button svg path
  ].freeze

  ALLOWED_ATTRIBUTES = %w[
    href src alt title class target rel style
    data-controller data-action data-clipboard-target
    aria-label aria-hidden role type
    viewBox fill stroke stroke-width stroke-linecap stroke-linejoin d
  ].freeze

  # ------------------------------------------------------------------
  # Callout syntax
  # ------------------------------------------------------------------
  # Use GitHub-flavored fenced callout syntax in blog posts:
  #
  #   :::tip
  #   Pro tip body content here. Can span multiple paragraphs.
  #   :::
  #
  # Supported types: info, tip, warning, danger.
  # ------------------------------------------------------------------
  CALLOUT_TYPES = {
    "info"    => {
      label: "Info",
      icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>)
    },
    "tip"     => {
      label: "Tip",
      icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>)
    },
    "warning" => {
      label: "Warning",
      icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>)
    },
    "danger"  => {
      label: "Danger",
      icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>)
    }
  }.freeze

  CALLOUT_REGEX = /^:::(#{CALLOUT_TYPES.keys.join('|')})\s*\n(.*?)\n:::\s*$/m

  class HTMLRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      lang = language.to_s.strip.presence || "plaintext"
      lang_display = ERB::Util.html_escape(lang)
      escaped = ERB::Util.html_escape(code)

      <<~HTML.strip
        <figure class="code-block" data-controller="clipboard">
          <figcaption class="code-block-header">
            <span class="code-block-language">#{lang_display}</span>
            <button type="button" class="code-block-copy" data-clipboard-target="button" data-action="click->clipboard#copy" aria-label="Copy code">
              <svg class="code-block-copy-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
              <span class="code-block-copy-label" data-clipboard-target="label">Copy</span>
            </button>
          </figcaption>
          <pre><code class="language-#{lang_display}">#{escaped}</code></pre>
        </figure>
      HTML
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

    preprocessed = preprocess_callouts(markdown)
    renderer = HTMLRenderer.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" })
    html = Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(preprocessed)
    sanitize(html).html_safe
  end

  def self.render_with_highlighting(markdown)
    return "" if markdown.blank?

    preprocessed = preprocess_callouts(markdown)
    renderer = HighlightedRenderer.new(hard_wrap: true,
                                       link_attributes: { target: "_blank", rel: "noopener" })
    html = Redcarpet::Markdown.new(renderer, **EXTENSIONS).render(preprocessed)
    sanitize(html).html_safe
  end

  # Converts :::tip / :::info / :::warning / :::danger blocks to the HTML
  # structure our CSS styles. Runs before Redcarpet so the embedded HTML is
  # passed through as a block and then individually sanitized at the end.
  def self.preprocess_callouts(markdown)
    markdown.gsub(CALLOUT_REGEX) do |_match|
      type = Regexp.last_match(1)
      body = Regexp.last_match(2).strip
      meta = CALLOUT_TYPES[type]

      # Render the body as markdown inline so bold/links/inline-code work.
      # Use a fresh renderer (no callout preprocess) to avoid recursion.
      body_renderer = HTMLRenderer.new(hard_wrap: false, link_attributes: { target: "_blank", rel: "noopener" })
      body_html = Redcarpet::Markdown.new(body_renderer, **EXTENSIONS).render(body)

      <<~HTML
        <aside class="callout callout-#{type}" role="note" aria-label="#{meta[:label]}">
          #{meta[:icon]}
          <div class="callout-body">
        #{body_html}
          </div>
        </aside>
      HTML
    end
  end

  def self.sanitize(html)
    Rails::HTML5::SafeListSanitizer.new.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end
  private_class_method :sanitize, :preprocess_callouts
end
