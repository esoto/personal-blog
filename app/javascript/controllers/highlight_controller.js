import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="highlight"
// Initializes highlight.js on code blocks within its scope.
// Adds language labels and handles Turbo navigations via connect/disconnect.
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
      this.addLanguageLabel(block)
    })
  }

  addLanguageLabel(block) {
    const pre = block.closest("pre")
    if (!pre || pre.querySelector(".code-language-label")) return

    const langClass = Array.from(block.classList).find((c) => c.startsWith("language-"))
    const language = langClass ? langClass.replace("language-", "") : null

    if (language) {
      const label = document.createElement("span")
      label.className = "code-language-label"
      label.textContent = language
      pre.appendChild(label)
    }
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

    const labels = this.element.querySelectorAll(".code-language-label")
    labels.forEach((label) => label.remove())
  }
}
