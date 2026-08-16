<!-- Every screen opens the same way: a title, one line that says what is on
     the screen, and the controls (usually the day strip) on the right. -->
<script lang="ts">
  import type { Snippet } from 'svelte'

  let {
    title,
    description,
    children,
  }: {
    title: string
    description?: string
    children?: Snippet
  } = $props()
</script>

<div class="page-header">
  <div class="page-header__text">
    <h1 class="bx--type-productive-heading-04">{title}</h1>
    {#if description}
      <p class="bx--type-body-long-01">{description}</p>
    {/if}
  </div>
  {#if children}
    <div class="page-header__controls">{@render children()}</div>
  {/if}
</div>

<style>
  .page-header {
    display: flex;
    flex-wrap: wrap;
    align-items: flex-end;
    justify-content: space-between;
    gap: var(--cds-spacing-05);
  }

  .page-header__text {
    min-width: 0;
  }

  .page-header__text p {
    margin-block-start: var(--cds-spacing-02);
    max-width: 42rem;
    color: var(--cds-text-02);
  }

  /* The controls keep their width when there is room and wrap to their own
     line when there is not — but never wider than the page, or a scrolling
     control inside them drags the whole layout sideways. */
  .page-header__controls {
    flex-shrink: 0;
    min-width: 0;
    max-width: 100%;
  }
</style>
