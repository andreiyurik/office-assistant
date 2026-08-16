<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import { ContentSwitcher, Switch } from 'carbon-components-svelte'
  import { asDate } from '@/lib/format'

  let {
    days,
    selected,
    hrefFor,
  }: {
    days: string[]
    selected: string
    hrefFor: (day: string) => string
  } = $props()

  // The first day in the strip is always today.
  const today = $derived(days[0])

  // The switcher keeps its own selection, so it is re-synced from the props
  // after every visit. A click moves it before the server answers, which is
  // why this only runs when the selected day actually changes.
  let selectedIndex = $state(0)

  $effect(() => {
    selectedIndex = days.indexOf(selected)
  })

  function label(day: string): string {
    if (day === today) return 'сегодня'

    const date = asDate(day)
    return `${date.toLocaleDateString('ru-RU', { weekday: 'short' })} ${date.getDate()}`
  }
</script>

<!-- Manual selection mode: the arrow keys move focus and Enter opens the day,
     so the keyboard never changes the page by drifting through the strip. -->
<div class="day-strip">
  <ContentSwitcher bind:selectedIndex selectionMode="manual" aria-label="День">
    {#each days as day (day)}
      <Switch text={label(day)} onclick={() => router.visit(hrefFor(day))} />
    {/each}
  </ContentSwitcher>
</div>

<style>
  /* Five days need room for a weekday and a number; Carbon's default lets a
     switch shrink until the label is clipped. Five of them are wider than a
     phone, so below the medium breakpoint the strip scrolls sideways — today
     is the first item, so the days people actually pick stay in view. */
  .day-strip {
    max-width: 100%;
    overflow-x: auto;
  }

  .day-strip :global(.bx--content-switcher-btn) {
    min-width: 5.5rem;
    white-space: nowrap;
  }

  @media (min-width: 42rem) {
    .day-strip {
      overflow-x: visible;
    }
  }
</style>
