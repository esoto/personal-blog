import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="highlight"
// Initializes highlight.js on code blocks within its scope.
// Language labels are now rendered server-side by MarkdownRenderer — this
// controller only handles syntax coloring and respects Turbo navigations
// via connect/disconnect.
export default class extends Controller {
  connect() {
    this.originalContents = new Map()
    this.highlightCodeBlocks()
  }

  disconnect() {
    this.cleanup()
  }

  highlightCodeBlocks() {
    if (typeof hljs === "undefined") {
      this.retryTimeout = setTimeout(() => this.highlightCodeBlocks(), 100)
      return
    }

    const codeBlocks = this.element.querySelectorAll("pre code")

    codeBlocks.forEach((block) => {
      if (block.dataset.highlighted === "yes") return

      this.originalContents.set(block, block.innerHTML)
      hljs.highlightElement(block)
    })
  }

  cleanup() {
    if (this.retryTimeout) clearTimeout(this.retryTimeout)

    const codeBlocks = this.element.querySelectorAll("pre code")
    codeBlocks.forEach((block) => {
      if (this.originalContents?.has(block)) {
        block.innerHTML = this.originalContents.get(block)
      }
      delete block.dataset.highlighted
      block.classList.remove("hljs")
    })
    this.originalContents?.clear()
  }
}
