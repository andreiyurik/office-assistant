<script lang="ts">
  // Messages float above the page instead of standing in the flow: an error
  // must never push the grid or the map that the person is aiming at.
  import { ToastNotification } from 'carbon-components-svelte'

  let { message }: { message: string | null } = $props()

  let shown = $state(false)

  $effect(() => {
    if (message) shown = true
  })

  // Every message from the server is written as "what happened. what to do
  // next", which is the shape a Carbon toast already has: title, then subtitle.
  function split(text: string): { title: string; subtitle: string } {
    const end = text.indexOf('. ')
    if (end === -1) return { title: text, subtitle: '' }

    return { title: text.slice(0, end + 1), subtitle: text.slice(end + 2) }
  }
</script>

{#if shown && message}
  {@const parts = split(message)}
  <div class="toast">
    <ToastNotification
      kind="error"
      lowContrast
      title={parts.title}
      subtitle={parts.subtitle}
      timeout={6000}
      closeButtonDescription="Закрыть"
      on:close={() => (shown = false)}
    />
  </div>
{/if}

<style>
  .toast {
    position: fixed;
    inset-block-end: var(--cds-spacing-05);
    inset-inline-end: var(--cds-spacing-05);
    z-index: 9000;
    max-width: calc(100vw - var(--cds-spacing-07));
  }

  /* Carbon fixes a toast at 18rem, which is meant for a few words. Ours carry
     a sentence and the advice that follows it, so the box grows to fit. */
  .toast :global(.bx--toast-notification) {
    margin: 0;
    width: auto;
    min-width: 18rem;
    max-width: min(26rem, 100%);
  }
</style>
