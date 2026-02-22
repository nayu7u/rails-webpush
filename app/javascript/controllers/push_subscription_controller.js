import { Controller } from "@hotwired/stimulus"

// Manages Web Push subscription lifecycle via the Push API.
// Connects to the PushSubscriptionsController JSON endpoints.
export default class extends Controller {
  static values = {
    vapidPublicKey:  String,
    subscribeUrl:    String,
    unsubscribeUrl:  String
  }

  static targets = ["button", "status"]

  async connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.renderStatus("error", "This browser does not support Web Push.")
      return
    }

    if (!this.vapidPublicKeyValue) {
      this.renderStatus("error", "VAPID public key is not configured on the server.")
      if (this.hasButtonTarget) this.buttonTarget.disabled = true
      return
    }

    // Register / retrieve the service worker
    this.registration = await navigator.serviceWorker.register("/service-worker", { scope: "/" })
    await navigator.serviceWorker.ready

    // Check existing subscription
    this.subscription = await this.registration.pushManager.getSubscription()
    this.updateUI()
  }

  // Toggle subscribe / unsubscribe
  async toggle() {
    this.buttonTarget.disabled = true

    try {
      if (this.subscription) {
        await this.unsubscribe()
      } else {
        await this.subscribe()
      }
    } catch (error) {
      console.error("Push subscription error:", error)
      this.renderStatus("error", `Error: ${error.message}`)
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  async subscribe() {
    const applicationServerKey = this.urlBase64ToUint8Array(this.vapidPublicKeyValue)

    this.subscription = await this.registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey
    })

    const json = this.subscription.toJSON()

    const response = await fetch(this.subscribeUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({
        subscription: {
          endpoint:   json.endpoint,
          p256dh:     json.keys.p256dh,
          auth:       json.keys.auth,
          user_agent: navigator.userAgent
        }
      })
    })

    if (!response.ok) throw new Error("Server rejected subscription")
    this.updateUI()
  }

  async unsubscribe() {
    const endpoint = this.subscription.endpoint
    const unsubscribed = await this.subscription.unsubscribe()
    if (!unsubscribed) throw new Error("Failed to unsubscribe from push service")

    this.subscription = null
    this.updateUI()

    const response = await fetch(this.unsubscribeUrlValue, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ endpoint })
    })

    if (!response.ok) throw new Error("Unsubscribed locally, but server cleanup failed. Please retry.")
  }

  updateUI() {
    if (this.subscription) {
      this.buttonTarget.textContent = "Unsubscribe"
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.replace("bg-blue-600", "bg-red-600")
      this.buttonTarget.classList.replace("hover:bg-blue-700", "hover:bg-red-700")
      this.renderStatus("success", "Subscribed! You will receive push notifications.")
    } else {
      this.buttonTarget.textContent = "Subscribe to Push"
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.replace("bg-red-600", "bg-blue-600")
      this.buttonTarget.classList.replace("hover:bg-red-700", "hover:bg-blue-700")
      this.renderStatus("info", "Click the button to subscribe to push notifications.")
    }
  }

  renderStatus(type, message) {
    const colors = {
      success: "bg-green-50 border-green-300 text-green-800",
      error:   "bg-red-50 border-red-300 text-red-800",
      info:    "bg-blue-50 border-blue-300 text-blue-800"
    }

    this.statusTarget.className = `mb-6 p-4 rounded-lg border ${colors[type] || colors.info}`
    this.statusTarget.innerHTML = `<p>${message}</p>`
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  // Convert URL-safe Base64 VAPID key to Uint8Array for applicationServerKey
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64  = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const raw     = atob(base64)
    const array   = new Uint8Array(raw.length)
    for (let i = 0; i < raw.length; i++) {
      array[i] = raw.charCodeAt(i)
    }
    return array
  }
}
