import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
//
// Each code block figure (rendered server-side by MarkdownRenderer) includes
// its own clipboard controller with a `button` and `label` target. Click the
// button → copy the sibling <pre><code> contents to the clipboard and briefly
// toggle the label to "Copied!".
export default class extends Controller {
  static targets = ["button", "label"]

  copy(event) {
    event.preventDefault()

    const pre = this.element.querySelector("pre")
    if (!pre) return

    const text = pre.innerText
    const button = this.hasButtonTarget ? this.buttonTarget : event.currentTarget
    const label  = this.hasLabelTarget  ? this.labelTarget  : null

    const done = (ok) => {
      if (label) label.textContent = ok ? "Copied!" : "Failed"
      if (button) button.classList.add("is-copied")
      clearTimeout(this.resetTimer)
      this.resetTimer = setTimeout(() => {
        if (label) label.textContent = "Copy"
        if (button) button.classList.remove("is-copied")
      }, 1800)
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(() => done(true)).catch(() => this.legacyCopy(text, done))
    } else {
      this.legacyCopy(text, done)
    }
  }

  legacyCopy(text, done) {
    try {
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.setAttribute("readonly", "")
      textarea.style.position = "absolute"
      textarea.style.left = "-9999px"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)
      done(true)
    } catch (e) {
      done(false)
    }
  }

  disconnect() {
    clearTimeout(this.resetTimer)
  }
}
