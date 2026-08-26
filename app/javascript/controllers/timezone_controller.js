import { Controller } from "@hotwired/stimulus"

// Detects the browser's time zone and, if it differs from the one the server
// is currently using (stored in the `tz` cookie), records it and reloads so
// the page re-renders times in the user's local time zone.
export default class extends Controller {
  connect() {
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!timeZone) return

    const current = document.cookie.match(/(?:^|;\s*)tz=([^;]*)/)?.[1]
    if (current === timeZone) return

    document.cookie = `tz=${timeZone}; path=/; max-age=31536000; samesite=lax`
    window.location.reload()
  }
}