class MarkdownRenderer
  # ------------------------------------------------------------------
  # Callouts — :::info / :::tip / :::warning / :::danger admonitions
  # ------------------------------------------------------------------
  # Use in a blog post body like:
  #
  #   :::tip
  #   Pro tip body content here. Can span multiple paragraphs and
  #   include **bold**, `inline code`, and [links](https://ex.com).
  #   :::
  #
  # Implementation is a line-based state machine rather than a single
  # regex because:
  #   1. Regex matching risks false matches inside fenced code blocks
  #      — a ```ruby block containing `:::tip` on a line would be
  #      silently rewritten.
  #   2. Malformed callouts (missing close fence) should degrade
  #      gracefully to raw text rather than silently swallowing
  #      the rest of the document.
  #   3. Adjacent callouts of the same type should not merge.
  # ------------------------------------------------------------------
  module Callouts
    TYPES = {
      "info" => {
        label: "Info",
        icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>)
      },
      "tip" => {
        label: "Tip",
        icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>)
      },
      "warning" => {
        label: "Warning",
        icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>)
      },
      "danger" => {
        label: "Danger",
        icon:  %(<svg class="callout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>)
      }
    }.freeze

    CODE_FENCE = /\A```/
    OPEN_FENCE = /\A:::(\w+)\s*\z/
    CLOSE_FENCE = /\A:::\s*\z/

    # Preprocesses markdown, replacing recognised callout blocks with
    # the HTML aside wrapper. Unrecognised types and unclosed blocks
    # pass through as raw markdown.
    def self.preprocess(markdown, body_markdown_renderer)
      out = []
      in_code = false
      open_type = nil
      buffer = []

      markdown.each_line do |line|
        stripped = line.chomp

        # Track fenced code blocks so we don't rewrite :::type that
        # happens to appear on its own line inside a code fence.
        if stripped.match?(CODE_FENCE)
          in_code = !in_code
          (open_type ? buffer : out) << line
          next
        end

        if in_code
          (open_type ? buffer : out) << line
          next
        end

        if open_type.nil?
          match = stripped.match(OPEN_FENCE)
          if match && TYPES.key?(match[1])
            open_type = match[1]
            buffer = []
          else
            out << line
          end
        else
          if stripped.match?(CLOSE_FENCE)
            body = buffer.join
            out << render_callout(open_type, body, body_markdown_renderer)
            open_type = nil
            buffer = []
          else
            buffer << line
          end
        end
      end

      # Unclosed callout block: flush the open fence and buffered body
      # as raw text so readers at least see the content, and fix is
      # obvious from the malformed markup on screen.
      if open_type
        out << ":::#{open_type}\n"
        out.concat(buffer)
      end

      out.join
    end

    def self.render_callout(type, body_markdown, body_renderer)
      meta = TYPES.fetch(type)
      body_html = body_renderer.render(body_markdown.strip)

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
end
