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
</script>

<div class="flex flex-wrap gap-1.5">
  {#each days as day (day)}
    <Link
      href={hrefFor(day)}
      class="flex w-16 flex-col items-center rounded-lg border px-2 py-1.5 text-center transition-colors {day ===
      selected
        ? 'border-primary bg-primary text-primary-foreground'
        : 'hover:bg-muted'}"
    >
      <span class="text-xs capitalize opacity-80">
        {asDate(day).toLocaleDateString('ru-RU', { weekday: 'short' })}
      </span>
      <span class="text-lg leading-tight font-semibold">{asDate(day).getDate()}</span>
    </Link>
  {/each}
</div>
