<script lang="ts">
  // Messages float above the page instead of standing in the flow: an error
  // must never push the grid or the map that the person is aiming at.
  let { message }: { message: string | null } = $props()

  let shown = $state(false)

  $effect(() => {
    if (!message) return

    shown = true
    const timer = setTimeout(() => (shown = false), 6000)

    return () => clearTimeout(timer)
  })
</script>

{#if shown && message}
  <div
    role="status"
    class="fixed right-4 bottom-4 z-50 max-w-sm rounded-lg border border-destructive/30 bg-background px-4 py-3 text-sm shadow-lg"
  >
    <div class="flex items-start gap-3">
      <span class="text-destructive">{message}</span>
      <button
        type="button"
        onclick={() => (shown = false)}
        class="shrink-0 text-muted-foreground hover:text-foreground"
        aria-label="Закрыть"
      >
        ✕
      </button>
    </div>
  </div>
{/if}
