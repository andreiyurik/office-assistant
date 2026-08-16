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

<div class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
  <div class="min-w-0">
    <h1 class="text-2xl font-semibold tracking-tight">{title}</h1>
    {#if description}
      <p class="mt-1 text-sm text-muted-foreground">{description}</p>
    {/if}
  </div>
  {#if children}
    <div class="shrink-0">{@render children()}</div>
  {/if}
</div>
