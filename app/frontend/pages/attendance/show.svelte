<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import {
    breakpointObserver,
    Button,
    DataTable,
    Tag,
    Tile,
    Toolbar,
    ToolbarContent,
    ToolbarSearch,
  } from 'carbon-components-svelte'
  import ArrowRight from 'carbon-icons-svelte/lib/ArrowRight.svelte'
  import LocationFilled from 'carbon-icons-svelte/lib/LocationFilled.svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
  import { asDate } from '@/lib/format'
  import { visitOnClick } from '@/lib/visit'

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

  // A four-column table is wider than a phone, and the column that would end up
  // off screen is the one with the action. Carbon's own breakpoint store drops
  // the team on a small screen: it is already the filter above the table, and
  // the tag on the row says whether the person is a teammate.
  const narrow = breakpointObserver().smallerThan('md')

  // `as const` is not decoration: DataTable types a header key as a literal
  // key of the row, so a widened string[] does not typecheck.
  const allHeaders = [
    { key: 'name', value: 'Сотрудник' },
    { key: 'team_name', value: 'Команда' },
    { key: 'desk', value: 'Место' },
    // The last column holds the row action and has no heading of its own.
    { key: 'near', empty: true },
  ] as const

  const headers = $derived($narrow ? allHeaders.filter((h) => h.key !== 'team_name') : allHeaders)

  // Teammates first: the table has no row grouping, so the order carries what
  // the two headings used to say and a tag repeats it on the row itself.
  const rows = $derived(
    [...people]
      .sort((a, b) => Number(b.is_teammate) - Number(a.is_teammate))
      .map((person) => ({
        id: person.id,
        name: person.name,
        team_name: person.team_name,
        desk: `${person.desk_name} · ${person.zone_name}`,
        near: '',
        person,
      })),
  )

  const description = $derived.by(() => {
    const when = selected_date === today ? 'Сегодня' : fullDate(selected_date)
    const count = `${people.length} ${peopleWord(people.length)}`
    if (selected_team_id || teammates_count === 0) return `${when} в офисе ${count}.`
    return `${when} в офисе ${count}, из них ${teammates_count} из вашей команды.`
  })

  const deskHref = $derived(`/desks?date=${selected_date}`)

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

  <div class="status">
    <Tile>
      {#if my_desk}
        <p>
          <LocationFilled size={20} aria-hidden="true" />
          <span>Вы в офисе, место <strong>{my_desk.name}</strong> · {my_desk.zone_name}</span>
        </p>
        <Button kind="tertiary" size="small" href={deskHref} onclick={visitOnClick(deskHref)}>
          Изменить место
        </Button>
      {:else}
        <p><span>Вас нет в списке на этот день.</span></p>
        <Button size="small" href={deskHref} onclick={visitOnClick(deskHref)}>Забронировать место</Button>
      {/if}
    </Tile>
  </div>

  <!-- The teams stay a one-click filter rather than a select: six of them fit,
       and picking one should cost the same as picking a day. -->
  <div class="teams" role="group" aria-label="Команда">
    <Tag
      interactive
      type={selected_team_id ? 'outline' : 'blue'}
      onclick={() => router.visit(href(selected_date, null))}
    >
      Все команды
    </Tag>
    {#each teams as team (team.id)}
      <Tag
        interactive
        type={selected_team_id === team.id ? 'blue' : 'outline'}
        onclick={() => router.visit(href(selected_date, team.id))}
      >
        {team.name}
      </Tag>
    {/each}
  </div>

  {#if people.length === 0}
    <div class="empty">
      <Tile>
        <p class="bx--type-body-long-01">
          {#if selected_team_id}
            В этот день из выбранной команды никто не бронировал место.
            Снимите фильтр, чтобы увидеть остальных.
          {:else}
            В этот день в офисе пока никого нет.
            Забронируйте место на карте — коллеги увидят вас в списке.
          {/if}
        </p>
        <Button kind="tertiary" size="small" href={deskHref} onclick={visitOnClick(deskHref)}>
          Открыть карту мест
        </Button>
      </Tile>
    </div>
  {:else}
    <div class="table">
      <DataTable {headers} {rows} sortable>
        <Toolbar size="sm">
          <ToolbarContent>
            <ToolbarSearch persistent shouldFilterRows placeholder="Поиск по имени или команде" />
          </ToolbarContent>
        </Toolbar>

        {#snippet cell({ row, cell })}
          {#if cell.key === 'name'}
            <span class="name">
              {row.person.name}
              {#if row.person.is_me}
                <Tag type="gray" size="sm">вы</Tag>
              {:else if row.person.is_teammate}
                <Tag type="blue" size="sm">{$narrow ? 'команда' : 'ваша команда'}</Tag>
              {/if}
            </span>
          {:else if cell.key === 'near'}
            {#if !row.person.is_me}
              {@const target = `/desks?date=${selected_date}&near=${row.person.id}`}
              <!-- Icon only on a phone: the label costs the width the desk
                   column needs, and the tooltip still carries it. -->
              <Button
                kind="ghost"
                size="small"
                icon={ArrowRight}
                iconDescription={$narrow ? `Сесть рядом с ${row.person.name}` : undefined}
                tooltipPosition="left"
                href={target}
                onclick={visitOnClick(target)}
              >
                {#if !$narrow}Сесть рядом{/if}
              </Button>
            {/if}
          {:else}
            {cell.value}
          {/if}
        {/snippet}
      </DataTable>
    </div>
  {/if}
</AppLayout>

<style>
  .status {
    margin-block-start: var(--cds-spacing-06);
  }

  .status :global(.bx--tile) {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: var(--cds-spacing-05);
  }

  .status p {
    display: flex;
    align-items: center;
    gap: var(--cds-spacing-03);
  }

  .status :global(svg) {
    flex-shrink: 0;
    fill: var(--cds-support-02);
  }

  .empty {
    margin-block-start: var(--cds-spacing-05);
    max-width: 34rem;
  }

  .empty :global(.bx--tile) {
    display: grid;
    justify-items: start;
    gap: var(--cds-spacing-05);
  }

  /* On a phone the chips keep to one row and scroll sideways, the way the day
     strip above them does. Without flex-shrink the row squeezes them until
     Carbon truncates the team names to one letter. */
  .teams {
    margin-block-start: var(--cds-spacing-05);
    display: flex;
    flex-wrap: nowrap;
    overflow-x: auto;
  }

  .teams :global(.bx--tag) {
    flex-shrink: 0;
  }

  /* Four columns are wider than a phone. Carbon scrolls the table inside its
     own container rather than letting it push the page sideways. */
  .table {
    margin-block-start: var(--cds-spacing-05);
    overflow-x: auto;
  }

  /* The name and its tag wrap rather than holding the column open: on a phone
     that width comes out of the desk column, which is what the row is for. */
  .name {
    display: inline-flex;
    flex-wrap: wrap;
    align-items: center;
    gap: var(--cds-spacing-03);
  }

  @media (min-width: 42rem) {
    .teams {
      flex-wrap: wrap;
      overflow-x: visible;
    }
  }
</style>
