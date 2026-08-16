<script lang="ts">
  // Messages float above the page instead of standing in the flow: an error
  // must never push the grid or the map that the person is aiming at.
  import WarningCircleIcon from 'phosphor-svelte/lib/WarningCircleIcon'
  import XIcon from 'phosphor-svelte/lib/XIcon'

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
      <WarningCircleIcon size={20} weight="fill" class="mt-px shrink-0 text-destructive" aria-hidden="true" />
      <span class="flex-1 text-foreground">{message}</span>
      <button
        type="button"
        onclick={() => (shown = false)}
        class="shrink-0 rounded text-muted-foreground hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
        aria-label="Закрыть"
      >
        <XIcon size={16} aria-hidden="true" />
      </button>
    </div>
  </div>
{/if}
