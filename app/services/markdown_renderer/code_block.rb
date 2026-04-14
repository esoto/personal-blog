class MarkdownRenderer
  # ------------------------------------------------------------------
  # CodeBlock — shared HTML markup for fenced code blocks.
  # ------------------------------------------------------------------
  # Called by both HTMLRenderer and HighlightedRenderer so the editor
  # preview and the published post share the same figure/figcaption
  # chrome (language label + copy button). The only difference between
  # the two renderers is what goes inside <code>: HTML-escaped plaintext
  # vs. Rouge-formatted highlighted HTML.
  # ------------------------------------------------------------------
  module CodeBlock
    COPY_ICON = <<~SVG.strip
      <svg class="code-block-copy-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
    SVG

    # Wraps code HTML in the standard figure/figcaption chrome.
    # `code_html` is expected to be already-escaped or already-formatted
    # — the caller controls whether plaintext or Rouge HTML is used.
    def self.render(language, code_html)
      lang = language.to_s.strip.presence || "plaintext"
      lang_display = ERB::Util.html_escape(lang)

      <<~HTML.strip
        <figure class="code-block" data-controller="clipboard">
          <figcaption class="code-block-header">
            <span class="code-block-language">#{lang_display}</span>
            <button type="button" class="code-block-copy" data-clipboard-target="button" data-action="click->clipboard#copy" aria-label="Copy code">
              #{COPY_ICON}
              <span class="code-block-copy-label" data-clipboard-target="label">Copy</span>
            </button>
          </figcaption>
          <pre><code class="language-#{lang_display}">#{code_html}</code></pre>
        </figure>
      HTML
    end
  end
end
