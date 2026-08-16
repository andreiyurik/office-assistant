<script lang="ts">
  import { Link } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import { asDate, initials } from '@/lib/format'
  import { Badge } from '@/lib/components/ui/badge'

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
  <h1 class="text-xl font-semibold tracking-tight">Кто в офисе</h1>

  <div class="mt-4">
    <DayStrip {days} selected={selected_date} hrefFor={(day) => href(day, selected_team_id)} />
  </div>

  <p class="mt-4 text-sm text-muted-foreground">
    {selected_date === today ? 'Сегодня' : fullDate(selected_date)} в офисе
    <span class="font-medium text-foreground">{people.length} {peopleWord(people.length)}</span>{#if !selected_team_id && teammates_count > 0}, из них
      <span class="font-medium text-foreground">{teammates_count}</span> из вашей команды{/if}.
  </p>

  <div
    class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg border px-4 py-2.5 text-sm"
  >
    {#if my_desk}
      <span>Вы в офисе, место <span class="font-medium">{my_desk.name}</span> · {my_desk.zone_name}</span>
      <Link href="/desks?date={selected_date}" class="font-medium underline underline-offset-4">
        Изменить
      </Link>
    {:else}
      <span class="text-muted-foreground">Вас нет в списке на этот день.</span>
      <Link
        href="/desks?date={selected_date}"
        class="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/80"
      >
        Забронировать место
      </Link>
    {/if}
  </div>

  <div class="mt-4 flex flex-wrap gap-1.5">
    <Link
      href={href(selected_date, null)}
      class="rounded-full border px-3 py-1 text-sm transition-colors {selected_team_id
        ? 'hover:bg-muted'
        : 'border-foreground bg-foreground text-background'}"
    >
      Все команды
    </Link>
    {#each teams as team (team.id)}
      <Link
        href={href(selected_date, team.id)}
        class="rounded-full border px-3 py-1 text-sm transition-colors {selected_team_id === team.id
          ? 'border-foreground bg-foreground text-background'
          : 'hover:bg-muted'}"
      >
        {team.name}
      </Link>
    {/each}
  </div>

  {#if people.length === 0}
    <div class="mt-6 rounded-lg border border-dashed px-4 py-10 text-center">
      <p class="text-sm text-muted-foreground">
        {#if selected_team_id}
          В этот день из выбранной команды никто не бронировал место.
          Снимите фильтр, чтобы увидеть остальных.
        {:else}
          В этот день в офисе пока никого нет.
          Забронируйте место на карте — коллеги увидят вас в списке.
        {/if}
      </p>
      <Link
        href="/desks?date={selected_date}"
        class="mt-3 inline-block text-sm font-medium underline underline-offset-4"
      >
        Открыть карту мест
      </Link>
    </div>
  {:else}
    <ul class="mt-4 divide-y rounded-lg border">
      {#each people as person (person.id)}
        <li class={person.is_teammate ? 'bg-muted/40' : ''}>
          <Link
            href="/desks?date={selected_date}&near={person.id}"
            title="Открыть карту рядом с {person.name}"
            class="group flex items-center gap-3 px-4 py-2.5 transition-colors hover:bg-muted"
          >
            <span
              class="flex size-8 shrink-0 items-center justify-center rounded-full bg-secondary text-xs font-medium text-secondary-foreground"
            >
              {initials(person.name)}
            </span>

            <span class="min-w-0 flex-1">
              <span class="block truncate text-sm font-medium">
                {person.name}{#if person.is_me}<span class="ml-1.5 text-xs text-muted-foreground">вы</span>{/if}
              </span>
              <span class="block truncate text-xs text-muted-foreground">{person.team_name}</span>
            </span>

            {#if !person.is_me}
              <span class="hidden text-xs text-muted-foreground group-hover:text-foreground sm:inline">
                Сесть рядом →
              </span>
            {/if}

            <Badge variant="secondary" class="shrink-0">
              Место {person.desk_name} · {person.zone_name}
            </Badge>
          </Link>
        </li>
      {/each}
    </ul>
  {/if}
</AppLayout>
