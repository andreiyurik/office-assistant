<script lang="ts">
  import { Link } from '@inertiajs/svelte'
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
</script>

<nav class="flex gap-1.5" aria-label="День">
  {#each days as day (day)}
    <Link
      href={hrefFor(day)}
      aria-current={day === selected ? 'date' : undefined}
      class="flex w-14 flex-col items-center rounded-lg border px-1 py-1.5 text-center transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none sm:w-16 {day ===
      selected
        ? 'border-primary bg-primary text-primary-foreground shadow-sm'
        : 'bg-background text-foreground hover:border-primary/40 hover:bg-primary/5'}"
    >
      <span class="text-[11px] capitalize {day === selected ? 'opacity-90' : 'text-muted-foreground'}">
        {day === today ? 'сегодня' : asDate(day).toLocaleDateString('ru-RU', { weekday: 'short' })}
      </span>
      <span class="text-lg leading-tight font-semibold tabular-nums">{asDate(day).getDate()}</span>
    </Link>
  {/each}
</nav>
