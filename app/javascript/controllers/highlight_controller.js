import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="highlight"
// Initializes highlight.js on code blocks within its scope.
// Adds language labels and handles Turbo navigations via connect/disconnect.
export default class extends Controller {
  connect() {
    this.highlightCodeBlocks()
  }

  disconnect() {
    this.cleanup()
  }

  highlightCodeBlocks() {
    const codeBlocks = this.element.querySelectorAll("pre code")

    codeBlocks.forEach((block) => {
      // Skip if already highlighted
      if (block.dataset.highlighted === "yes") return

      // Highlight the block
      if (typeof hljs !== "undefined") {
        hljs.highlightElement(block)
      }

      // Add language label
      this.addLanguageLabel(block)
    })
  }

  addLanguageLabel(block) {
    const pre = block.closest("pre")
    if (!pre || pre.querySelector(".code-language-label")) return

    // Determine the language from the class (hljs adds "language-xxx" class)
    const langClass = Array.from(block.classList).find((c) => c.startsWith("language-"))
    const language = langClass ? langClass.replace("language-", "") : null

    if (language) {
      const label = document.createElement("span")
      label.className = "code-language-label"
      label.textContent = language
      pre.style.position = "relative"
      pre.appendChild(label)
    }
  }

  cleanup() {
    // Remove highlighted state so blocks can be re-highlighted on next connect
    const codeBlocks = this.element.querySelectorAll("pre code")
    codeBlocks.forEach((block) => {
      delete block.dataset.highlighted
    })

    // Remove language labels
    const labels = this.element.querySelectorAll(".code-language-label")
    labels.forEach((label) => label.remove())
  }
}
