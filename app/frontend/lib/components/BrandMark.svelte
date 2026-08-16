<!-- The app's mark: a ring with a dot inside it — presence, "someone is here" —
     on a rounded tile with a soft gradient. Inline SVG, no icon library. -->
<script lang="ts">
  let { class: className = 'size-7' }: { class?: string } = $props()

  // Gradient ids must be unique per instance when the mark appears twice on a page.
  const id = `brand-${Math.random().toString(36).slice(2, 8)}`
</script>

<svg viewBox="0 0 32 32" class={className} aria-hidden="true">
  <defs>
    <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="oklch(0.62 0.17 262)" />
      <stop offset="1" stop-color="oklch(0.42 0.2 270)" />
    </linearGradient>
  </defs>
  <rect width="32" height="32" rx="8" fill="url(#{id})" />
  <circle cx="16" cy="16" r="7.5" fill="none" stroke="white" stroke-width="2.5" />
  <circle cx="16" cy="16" r="3" fill="white" />
</svg>
