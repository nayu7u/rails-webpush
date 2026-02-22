// Handle incoming push notifications
self.addEventListener("push", async (event) => {
  const data = event.data ? await event.data.json() : {}
  const title = data.title || "New Notification"
  const options = {
    body: data.body || "",
    icon: data.icon || "/icon.png",
    badge: data.badge || "/icon.png",
    data: { path: data.data?.path || "/" }
  }
  event.waitUntil(self.registration.showNotification(title, options))
})

// Handle notification click — focus existing window or open new one
self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetPath = event.notification.data?.path || "/"

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        const clientPath = new URL(client.url).pathname
        if (clientPath === targetPath && "focus" in client) {
          return client.focus()
        }
      }
      return clients.openWindow(targetPath)
    })
  )
})
