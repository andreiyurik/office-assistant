<!-- The app's mark: a rounded tile with a 2x2 grid — a floor plan at a glance.
     Inline SVG so there is no icon library to depend on. -->
<script lang="ts">
  let { class: className = 'size-7' }: { class?: string } = $props()
</script>

<svg viewBox="0 0 28 28" class={className} aria-hidden="true">
  <rect width="28" height="28" rx="7" class="fill-primary" />
  <rect x="7" y="7" width="6" height="6" rx="1.5" class="fill-primary-foreground" />
  <rect x="15" y="7" width="6" height="6" rx="1.5" class="fill-primary-foreground/60" />
  <rect x="7" y="15" width="6" height="6" rx="1.5" class="fill-primary-foreground/60" />
  <rect x="15" y="15" width="6" height="6" rx="1.5" class="fill-primary-foreground" />
</svg>
