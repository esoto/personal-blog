import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.dismissTimeout = setTimeout(() => this.fadeAndRemove(), 5000)
  }

  disconnect() {
    if (this.dismissTimeout) clearTimeout(this.dismissTimeout)
  }

  dismiss() {
    if (this.dismissTimeout) clearTimeout(this.dismissTimeout)
    this.fadeAndRemove()
  }

  fadeAndRemove() {
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }
}
