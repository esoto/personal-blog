import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.addCopyButtons()
  }

  disconnect() {
    this.removeCopyButtons()
  }

  addCopyButtons() {
    const preElements = this.element.querySelectorAll("pre")
    preElements.forEach((pre) => {
      if (pre.querySelector("[data-clipboard-button]")) return

      pre.style.position = "relative"

      const button = document.createElement("button")
      button.setAttribute("data-clipboard-button", "true")
      button.setAttribute("type", "button")
      button.setAttribute("aria-label", "Copy code to clipboard")
      button.className = [
        "absolute", "top-2", "right-2",
        "flex", "items-center", "gap-1.5",
        "px-2", "py-1",
        "text-xs", "font-medium",
        "text-text-secondary",
        "bg-bg-primary",
        "border", "border-border",
        "rounded",
        "hover:text-accent-blue", "hover:border-accent-blue",
        "transition-all", "duration-200",
        "cursor-pointer",
        "opacity-0", "group-hover:opacity-100",
        "focus:opacity-100", "focus:outline-none", "focus:ring-2", "focus:ring-accent-blue"
      ].join(" ")

      button.innerHTML = `${this.copyIconSvg}<span data-label>Copy</span>`

      button.addEventListener("click", (event) => this.copy(event))

      pre.classList.add("group")
      pre.appendChild(button)
    })
  }

  removeCopyButtons() {
    const buttons = this.element.querySelectorAll("[data-clipboard-button]")
    buttons.forEach((button) => button.remove())
  }

  async copy(event) {
    const button = event.currentTarget
    const pre = button.closest("pre")
    const code = pre.querySelector("code")
    const text = (code || pre).textContent

    try {
      await navigator.clipboard.writeText(text)
      this.showCopiedFeedback(button)
    } catch {
      this.fallbackCopy(text, button)
    }
  }

  fallbackCopy(text, button) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand("copy")
      this.showCopiedFeedback(button)
    } catch {
      // Silently fail
    } finally {
      document.body.removeChild(textarea)
    }
  }

  showCopiedFeedback(button) {
    const label = button.querySelector("[data-label]")
    const originalIcon = button.querySelector("svg")

    label.textContent = "Copied!"
    button.classList.add("text-accent-green", "border-accent-green")
    button.classList.remove("text-text-secondary")
    originalIcon.outerHTML = this.checkIconSvg

    setTimeout(() => {
      label.textContent = "Copy"
      button.classList.remove("text-accent-green", "border-accent-green")
      button.classList.add("text-text-secondary")
      button.querySelector("svg").outerHTML = this.copyIconSvg
    }, 2000)
  }

  get copyIconSvg() {
    return `<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
    </svg>`
  }

  get checkIconSvg() {
    return `<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
    </svg>`
  }
}
