/* ===========================================================
 * docsify sw.js
 * ===========================================================
 * Copyright 2025 @sockeon
 * Licensed under MIT
 * Register service worker for Sockeon documentation
 * ========================================================== */

const RUNTIME = 'docsify'
const HOSTNAME_WHITELIST = [
  self.location.hostname,
  'fonts.gstatic.com',
  'fonts.googleapis.com',
  'cdn.jsdelivr.net'
]

// The Util Function to cache request and response
// use in addEventListener('fetch', event => {})
const cacheable = req => {
  const url = new URL(req.url)
  const acceptHeaders = req.headers.get('Accept')
  const isHtmlRequest = acceptHeaders && acceptHeaders.includes('text/html')
  const isHttps = url.protocol === 'https:'

  // Skip cross-origin requests or non-HTML requests if not HTTPS
  if (HOSTNAME_WHITELIST.indexOf(url.hostname) === -1 || (!isHttps && self.location.hostname !== 'localhost')) {
    return false
  }

  const extension = url.pathname.split('.').pop()
  
  // Check if request is for HTML, CSS, JS or other important assets
  return [
    'html', 'css', 'js', 'json', 'md', 
    'woff', 'woff2', 'ttf', 'eot',
    'png', 'jpg', 'jpeg', 'svg', 'gif',
    'ico'
  ].includes(extension) || isHtmlRequest
}

/**
 * @Lifecycle Activate
 * New one activated when old is not being used.
 *
 * waitUntil(): activating ====> activated
 */
self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim())
})

/**
 * @Functional Fetch
 * All network requests are being intercepted here.
 *
 * void respondWith(Promise<Response> r)
 */
self.addEventListener('fetch', event => {
  // Skip some of cross-origin requests
  if (!cacheable(event.request)) {
    return
  }

  // Stale-while-revalidate
  // Similar to HTTP's stale-while-revalidate: serve from cache, while revalidating (and update) the cache in the background
  event.respondWith(
    caches.open(RUNTIME).then(cache => {
      return cache.match(event.request).then(cached => {
        const fetchPromise = fetch(event.request)
          .then(response => {
            // Update the cache if successful
            if (response.status === 200) {
              const responseClone = response.clone()
              cache.put(event.request, responseClone)
            }
            return response
          })
          .catch(e => {
            console.error('Service worker fetch failed:', e)
          })

        // Return the cached response if available, otherwise wait for the network response
        return cached || fetchPromise
      })
    })
  )
})
