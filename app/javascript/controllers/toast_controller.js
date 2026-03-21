import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.dismissTimeout = setTimeout(() => this.fadeAndRemove(), 5000)
  }

  disconnect() {
    if (this.dismissTimeout) clearTimeout(this.dismissTimeout)
    if (this.fadeTimeout) clearTimeout(this.fadeTimeout)
  }

  dismiss() {
    if (this.dismissTimeout) clearTimeout(this.dismissTimeout)
    this.fadeAndRemove()
  }

  fadeAndRemove() {
    if (this.fading) return
    this.fading = true
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"
    this.fadeTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
