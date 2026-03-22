import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]
  static values = { previewUrl: String }

  connect() {
    this.debounceTimer = null
    this.savedSelection = { start: 0, end: 0 }
    this.updatePreview()
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }

  saveSelection() {
    const textarea = this.inputTarget
    this.savedSelection = {
      start: textarea.selectionStart,
      end: textarea.selectionEnd
    }
  }

  onInput() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.updatePreview(), 300)
  }

  async updatePreview() {
    const markdown = this.inputTarget.value
    if (!markdown.trim()) {
      this.previewTarget.innerHTML = '<p class="text-text-muted italic">Preview will appear here...</p>'
      return
    }

    try {
      const response = await fetch(this.previewUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/html"
        },
        body: `markdown=${encodeURIComponent(markdown)}`
      })
      if (response.ok) {
        this.previewTarget.innerHTML = await response.text()
      }
    } catch (error) {
      console.error("Preview error:", error)
    }
  }

  // Toolbar actions - insert markdown syntax at cursor
  bold() { this.wrapSelection("**") }
  italic() { this.wrapSelection("_") }
  strikethrough() { this.wrapSelection("~~") }
  code() { this.wrapSelection("`") }

  heading() {
    this.insertAtLineStart("## ")
  }

  link() {
    const textarea = this.inputTarget
    const selected = textarea.value.substring(this.savedSelection.start, this.savedSelection.end)
    const replacement = selected ? `[${selected}](url)` : "[link text](url)"
    this.replaceSelection(replacement)
  }

  image() {
    this.replaceSelection("![alt text](image-url)")
  }

  codeBlock() {
    const textarea = this.inputTarget
    const selected = textarea.value.substring(this.savedSelection.start, this.savedSelection.end)
    const replacement = selected ? `\n\`\`\`\n${selected}\n\`\`\`\n` : '\n```language\ncode here\n```\n'
    this.replaceSelection(replacement)
  }

  bulletList() { this.insertAtLineStart("- ") }
  numberList() { this.insertAtLineStart("1. ") }
  quote() { this.insertAtLineStart("> ") }

  // Helpers
  wrapSelection(wrapper) {
    const textarea = this.inputTarget
    const start = this.savedSelection.start
    const end = this.savedSelection.end
    const selected = textarea.value.substring(start, end)
    const replacement = `${wrapper}${selected || "text"}${wrapper}`
    textarea.setRangeText(replacement, start, end, "select")
    textarea.focus()
    this.onInput()
  }

  replaceSelection(replacement) {
    const textarea = this.inputTarget
    const start = this.savedSelection.start
    const end = this.savedSelection.end
    textarea.setRangeText(replacement, start, end, "end")
    textarea.focus()
    this.onInput()
  }

  insertAtLineStart(prefix) {
    const textarea = this.inputTarget
    const start = this.savedSelection.start
    const lineStart = textarea.value.lastIndexOf("\n", start - 1) + 1
    textarea.setRangeText(prefix, lineStart, lineStart, "end")
    textarea.focus()
    this.onInput()
  }
}
