import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
//
// Each code block figure (rendered server-side by MarkdownRenderer) includes
// its own clipboard controller with a `button` and `label` target. Click the
// button → copy the sibling <pre><code> contents to the clipboard and briefly
// toggle the label to "Copied!".
export default class extends Controller {
  static targets = ["button", "label"]

  async copy(event) {
    event.preventDefault()

    const pre = this.element.querySelector("pre")
    if (!pre) return

    const text = pre.innerText
    const button = this.hasButtonTarget ? this.buttonTarget : event.currentTarget
    const label  = this.hasLabelTarget  ? this.labelTarget  : null

    try {
      await navigator.clipboard.writeText(text)
      this.flash(button, label, "Copied!", "is-copied")
    } catch {
      // writeText rejects on insecure contexts or missing user gesture;
      // let the user see a failure state rather than silently dying.
      this.flash(button, label, "Failed", "is-failed")
    }
  }

  flash(button, label, message, modifier) {
    if (label) label.textContent = message
    if (button) button.classList.add(modifier)
    clearTimeout(this.resetTimer)
    this.resetTimer = setTimeout(() => {
      if (label) label.textContent = "Copy"
      if (button) button.classList.remove(modifier)
    }, 1800)
  }

  disconnect() {
    clearTimeout(this.resetTimer)
  }
}
