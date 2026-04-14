import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
//
// Three-state theme toggle: light / system / dark. Persists the
// choice in localStorage.theme ("light" | "dark" | absent for
// system). The inline no-FOUC script in layouts/application.html.erb
// reads the same key before first paint and sets the `light` class
// on <html> when appropriate. This controller's job is to flip the
// class on click, keep the pressed-button state in sync with the
// current choice, and follow the system preference as it changes
// while the user has picked "system".
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: light)")
    this.mediaHandler = () => {
      if (this.currentMode() === "system") this.applySystem()
    }
    this.mediaQuery.addEventListener("change", this.mediaHandler)
    this.updateButtonStates()
  }

  disconnect() {
    if (this.mediaQuery && this.mediaHandler) {
      this.mediaQuery.removeEventListener("change", this.mediaHandler)
    }
  }

  setLight() {
    localStorage.setItem("theme", "light")
    document.documentElement.classList.add("light")
    this.updateButtonStates()
  }

  setDark() {
    localStorage.setItem("theme", "dark")
    document.documentElement.classList.remove("light")
    this.updateButtonStates()
  }

  setSystem() {
    localStorage.removeItem("theme")
    this.applySystem()
    this.updateButtonStates()
  }

  applySystem() {
    if (this.mediaQuery.matches) {
      document.documentElement.classList.add("light")
    } else {
      document.documentElement.classList.remove("light")
    }
  }

  updateButtonStates() {
    const mode = this.currentMode()
    this.buttonTargets.forEach(btn => {
      const isActive = btn.dataset.themeMode === mode
      btn.classList.toggle("is-active", isActive)
      btn.setAttribute("aria-pressed", isActive ? "true" : "false")
    })
  }

  currentMode() {
    const stored = localStorage.getItem("theme")
    if (stored === "light" || stored === "dark") return stored
    return "system"
  }
}
