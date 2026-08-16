<script lang="ts">
  import { Link } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
  import { asDate, initials } from '@/lib/format'
  import { Badge } from '@/lib/components/ui/badge'
  import { buttonVariants } from '@/lib/components/ui/button'

  type Person = {
    id: number
    name: string
    team_name: string
    is_teammate: boolean
    is_me: boolean
    desk_name: string
    zone_name: string
  }

  type Team = { id: number; name: string }

  let {
    selected_date,
    my_desk,
    days,
    teams,
    selected_team_id,
    people,
    teammates_count,
  }: {
    selected_date: string
    my_desk: { name: string; zone_name: string } | null
    days: string[]
    teams: Team[]
    selected_team_id: number | null
    people: Person[]
    teammates_count: number
  } = $props()

  const today = $derived(days[0])

  // Teammates first, as their own group, when the list is not filtered by team.
  const teammates = $derived(people.filter((person) => person.is_teammate))
  const others = $derived(people.filter((person) => !person.is_teammate))
  const grouped = $derived(!selected_team_id && teammates.length > 0 && others.length > 0)

  const description = $derived.by(() => {
    const when = selected_date === today ? 'Сегодня' : fullDate(selected_date)
    const count = `${people.length} ${peopleWord(people.length)}`
    if (selected_team_id || teammates_count === 0) return `${when} в офисе ${count}.`
    return `${when} в офисе ${count}, из них ${teammates_count} из вашей команды.`
  })

  function fullDate(iso: string): string {
    return asDate(iso).toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' })
  }

  function href(date: string, teamId: number | null): string {
    const query = new URLSearchParams({ date })
    if (teamId) query.set('team_id', String(teamId))
    return `/?${query.toString()}`
  }

  function peopleWord(count: number): string {
    const last = count % 10
    const twoLast = count % 100
    const genitive = last >= 2 && last <= 4 && !(twoLast >= 12 && twoLast <= 14)
    return genitive ? 'человека' : 'человек'
  }
</script>

<svelte:head>
  <title>Кто в офисе — Office Assistant</title>
</svelte:head>

<AppLayout>
  <PageHeader title="Кто в офисе" {description}>
    <DayStrip {days} selected={selected_date} hrefFor={(day) => href(day, selected_team_id)} />
  </PageHeader>

  <div
    class="mt-5 flex flex-wrap items-center justify-between gap-3 rounded-xl border px-4 py-3 text-sm {my_desk
      ? 'border-success/30 bg-success/5'
      : 'border-primary/20 bg-primary/5'}"
  >
    {#if my_desk}
      <span class="flex items-center gap-2">
        <span class="size-2 rounded-full bg-success" aria-hidden="true"></span>
        Вы в офисе, место <span class="font-medium">{my_desk.name}</span> · {my_desk.zone_name}
      </span>
      <Link href="/desks?date={selected_date}" class={buttonVariants({ variant: 'outline', size: 'sm' })}>
        Изменить место
      </Link>
    {:else}
      <span class="text-foreground">Вас нет в списке на этот день.</span>
      <Link href="/desks?date={selected_date}" class={buttonVariants({ size: 'sm' })}>
        Забронировать место
      </Link>
    {/if}
  </div>

  <!-- On a phone the chips scroll sideways in one row instead of stacking. -->
  <div class="-mx-4 mt-5 flex gap-1.5 overflow-x-auto px-4 pb-1 whitespace-nowrap sm:mx-0 sm:flex-wrap sm:px-0 sm:whitespace-normal" role="group" aria-label="Команда">
    <Link
      href={href(selected_date, null)}
      aria-pressed={!selected_team_id}
      class="rounded-full border px-3 py-1 text-sm transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none {selected_team_id
        ? 'hover:bg-muted'
        : 'border-primary/30 bg-primary/10 font-medium text-primary'}"
    >
      Все команды
    </Link>
    {#each teams as team (team.id)}
      <Link
        href={href(selected_date, team.id)}
        aria-pressed={selected_team_id === team.id}
        class="rounded-full border px-3 py-1 text-sm transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none {selected_team_id ===
        team.id
          ? 'border-primary/30 bg-primary/10 font-medium text-primary'
          : 'hover:bg-muted'}"
      >
        {team.name}
      </Link>
    {/each}
  </div>

  {#if people.length === 0}
    <div class="mt-6 rounded-xl border border-dashed px-4 py-12 text-center">
      <p class="mx-auto max-w-sm text-sm text-muted-foreground">
        {#if selected_team_id}
          В этот день из выбранной команды никто не бронировал место.
          Снимите фильтр, чтобы увидеть остальных.
        {:else}
          В этот день в офисе пока никого нет.
          Забронируйте место на карте — коллеги увидят вас в списке.
        {/if}
      </p>
      <Link href="/desks?date={selected_date}" class="{buttonVariants({ variant: 'outline', size: 'sm' })} mt-4">
        Открыть карту мест
      </Link>
    </div>
  {:else if grouped}
    {@render group('Ваша команда', teammates)}
    {@render group('Остальные', others)}
  {:else}
    <ul class="mt-5 divide-y overflow-hidden rounded-xl border">
      {#each people as person (person.id)}
        {@render row(person)}
      {/each}
    </ul>
  {/if}
</AppLayout>

{#snippet group(label: string, list: Person[])}
  <h2 class="mt-6 mb-2 text-xs font-medium tracking-wide text-muted-foreground uppercase">
    {label} <span class="ml-1 tabular-nums">{list.length}</span>
  </h2>
  <ul class="divide-y overflow-hidden rounded-xl border">
    {#each list as person (person.id)}
      {@render row(person)}
    {/each}
  </ul>
{/snippet}

{#snippet row(person: Person)}
  <li>
    <Link
      href="/desks?date={selected_date}&near={person.id}"
      title="Открыть карту рядом с {person.name}"
      class="group flex items-center gap-3 px-4 py-2.5 transition-colors hover:bg-muted/60 focus-visible:bg-muted/60 focus-visible:outline-none"
    >
      <span
        class="flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold {person.is_teammate
          ? 'bg-primary/10 text-primary'
          : 'bg-secondary text-secondary-foreground'}"
        aria-hidden="true"
      >
        {initials(person.name)}
      </span>

      <span class="min-w-0 flex-1">
        <span class="block truncate text-sm font-medium">
          {person.name}{#if person.is_me}<span class="ml-1.5 text-xs font-normal text-muted-foreground">вы</span>{/if}
        </span>
        <span class="block truncate text-xs text-muted-foreground">{person.team_name}</span>
      </span>

      {#if !person.is_me}
        <span class="hidden text-xs text-muted-foreground transition-colors group-hover:text-primary sm:inline">
          Сесть рядом →
        </span>
      {/if}

      <Badge variant="secondary" class="shrink-0 tabular-nums">
        <span class="hidden sm:inline">Место&nbsp;</span>{person.desk_name} · {person.zone_name}
      </Badge>
      <span class="text-muted-foreground/60 sm:hidden" aria-hidden="true">›</span>
    </Link>
  </li>
{/snippet}
