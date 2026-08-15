import { createInertiaApp } from '@inertiajs/svelte'

createInertiaApp({
  pages: "../pages",

  // Inertia reads the CSRF token from the XSRF-TOKEN cookie that Rails sets and
  // sends it back in this header, which is the one Rails checks.
  http: {
    xsrfHeaderName: "X-CSRF-Token",
  },

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" }
    },
  },
})
