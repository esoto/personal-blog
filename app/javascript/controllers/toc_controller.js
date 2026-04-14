import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toc"
//
// Builds a table of contents from h2[id] headings inside the target
// article element and tracks the active section by watching scroll
// position. One controller instance drives either the desktop sticky
// sidebar or the mobile collapsible — each has its own list target.
export default class extends Controller {
  static targets = ["list"]
  static values = {
    articleSelector: { type: String, default: "article .prose-dark" },
    offset: { type: Number, default: 120 }
  }

  connect() {
    const article = document.querySelector(this.articleSelectorValue)
    if (!article) return

    this.headings = Array.from(article.querySelectorAll("h2[id]"))
    if (this.headings.length === 0) {
      this.element.hidden = true
      return
    }

    this.buildLists()

    this.scrollHandler = () => this.scheduleUpdate()
    window.addEventListener("scroll", this.scrollHandler, { passive: true })
    window.addEventListener("resize", this.scrollHandler, { passive: true })
    this.updateActive()
  }

  disconnect() {
    if (this.scrollHandler) {
      window.removeEventListener("scroll", this.scrollHandler)
      window.removeEventListener("resize", this.scrollHandler)
    }
    if (this.rafId) cancelAnimationFrame(this.rafId)
    if (this.clickSettleTimer) clearTimeout(this.clickSettleTimer)
  }

  buildLists() {
    const markup = this.headings
      .map(h => `<li><a href="#${h.id}" class="toc-link" data-heading-id="${h.id}">${escapeHtml(h.textContent)}</a></li>`)
      .join("")
    this.listTargets.forEach(list => { list.innerHTML = markup })
    // Anchor clicks scroll the page but the scroll event may not
    // arrive (or may arrive before the final scroll position is
    // applied), so set the active state explicitly on click and
    // re-measure once the browser has had time to settle.
    this.element.querySelectorAll(".toc-link").forEach(link => {
      link.addEventListener("click", () => this.handleLinkClick(link.dataset.headingId))
    })
  }

  handleLinkClick(id) {
    this.setActive(id)
    if (this.clickSettleTimer) clearTimeout(this.clickSettleTimer)
    this.clickSettleTimer = setTimeout(() => {
      this.setActive(id)
      this.updateActive()
    }, 250)
  }

  scheduleUpdate() {
    if (this.rafId) return
    this.rafId = requestAnimationFrame(() => {
      this.rafId = null
      this.updateActive()
    })
  }

  updateActive() {
    // Active is the last heading whose top edge is above the
    // sticky-nav offset. If nothing is above the offset yet
    // (reader is above the first heading), leave the current state
    // alone so a click-set highlight isn't prematurely cleared.
    let currentId = null
    for (const h of this.headings) {
      if (h.getBoundingClientRect().top <= this.offsetValue) {
        currentId = h.id
      } else {
        break
      }
    }
    if (currentId) this.setActive(currentId)
  }

  setActive(id) {
    this.element.querySelectorAll(".toc-link").forEach(link => {
      link.classList.toggle("is-active", link.dataset.headingId === id)
    })
  }
}

function escapeHtml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
}
