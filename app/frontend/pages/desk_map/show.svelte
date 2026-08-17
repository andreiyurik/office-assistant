<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import { Button, Modal, SelectableTile, Tile, Toggle } from 'carbon-components-svelte'
  import LocationFilled from 'carbon-icons-svelte/lib/LocationFilled.svelte'
  import StarFilled from 'carbon-icons-svelte/lib/StarFilled.svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
  import Toast from '@/lib/components/Toast.svelte'
  import { firstError, initials } from '@/lib/format'

  type TakenBy = {
    name: string
    team_name: string
    is_me: boolean
    is_teammate: boolean
  }

  type Desk = {
    id: number
    name: string
    row: number
    col: number
    is_default: boolean
    is_near_target: boolean
    taken_by: TakenBy | null
  }

  type Near = {
    name: string
    desk_id: number | null
    desk_name: string | null
    zone_id: number | null
  }

  type Zone = {
    id: number
    name: string
    is_mine: boolean
    free_count: number
    min_row: number
    min_col: number
    desks: Desk[]
  }

  let {
    selected_date,
    days,
    zones,
    near,
    my_booking,
    default_desk,
    recurring,
    errors = {},
  }: {
    selected_date: string
    days: string[]
    zones: Zone[]
    near: Near | null
    my_booking: { id: number; desk_id: number; desk_name: string; zone_name: string } | null
    default_desk: { id: number; name: string; zone_name: string; free: boolean } | null
    recurring: { weekdays: number[]; desk_id: number; desk_name: string } | null
    errors?: Record<string, string[] | string>
  } = $props()

  const weekdayOptions = [
    { value: 1, label: 'Понедельник' },
    { value: 2, label: 'Вторник' },
    { value: 3, label: 'Среда' },
    { value: 4, label: 'Четверг' },
    { value: 5, label: 'Пятница' },
  ]

  // The days are shown as chosen only when the schedule is about the desk on
  // screen — otherwise the person would see ticks next to another desk.
  const scheduleDays = $derived(
    recurring && my_booking && recurring.desk_id === my_booking.desk_id ? recurring.weekdays : [],
  )

  const myZone = $derived(zones.find((zone) => zone.is_mine))
  const nearZone = $derived(near ? zones.find((zone) => zone.id === near.zone_id) : undefined)
  const roomiest = $derived(
    zones
      .filter((zone) => !zone.is_mine && zone.free_count > 0)
      .sort((a, b) => b.free_count - a.free_count)[0],
  )

  const error = $derived(firstError(errors))
  const freeTotal = $derived(zones.reduce((sum, zone) => sum + zone.free_count, 0))
  const deskTotal = $derived(zones.reduce((sum, zone) => sum + zone.desks.length, 0))

  // Taking a second desk moves the booking, so the move is confirmed instead of
  // happening silently. Two variables rather than one: the desk stays put while
  // the dialog fades out, so the sentence inside it does not blank mid-close.
  let moveTo = $state<Desk | null>(null)
  let moveOpen = $state(false)

  // SelectableTile keeps its own checked state and flips it on click, so the
  // map has to hold that state too — otherwise a cancelled move leaves a tick
  // on a desk nobody booked. Re-read from the server after every response,
  // and again when a move is called off.
  let selected = $state<Record<number, boolean>>({})

  function syncSelected(): void {
    selected = Object.fromEntries(
      zones.flatMap((zone) => zone.desks).map((desk) => [desk.id, desk.taken_by?.is_me ?? false]),
    )
  }

  $effect(syncSelected)

  function cancelMove(): void {
    moveOpen = false
    syncSelected()
  }

  function toggleWeekday(day: number, on: boolean): void {
    if (!my_booking) return

    const next = on ? [...scheduleDays, day].sort() : scheduleDays.filter((chosen) => chosen !== day)

    router.patch(
      '/recurring_schedule',
      { resource_id: my_booking.desk_id, weekdays: next, date: selected_date },
      { preserveScroll: true },
    )
  }

  function book(deskId: number): void {
    router.post(
      '/desk_bookings',
      { resource_id: deskId, date: selected_date },
      { preserveScroll: true },
    )
  }

  function cancel(bookingId: number): void {
    router.delete(`/desk_bookings/${bookingId}`, { preserveScroll: true })
  }

  function chooseDesk(desk: Desk, event: MouseEvent): void {
    if (desk.taken_by?.is_me) {
      cancel(my_booking!.id)
      return
    }

    if (my_booking) {
      // The tile is a label over a checkbox, and the browser hands focus to
      // that checkbox after this handler returns — over the focus the modal
      // has just taken, which leaves Escape with nothing listening. Stopping
      // the activation also keeps a tick off a desk that is not booked yet.
      // Focus still has to land on the tile, or Carbon has nowhere to put it
      // back when the dialog closes.
      event.preventDefault()
      ;(event.currentTarget as HTMLLabelElement | null)?.control?.focus()
      moveTo = desk
      moveOpen = true
      return
    }

    book(desk.id)
  }

  function confirmMove(): void {
    if (!moveTo) return

    moveOpen = false
    book(moveTo.id)
  }

  function columns(zone: Zone): number {
    return Math.max(...zone.desks.map((desk) => desk.col)) - zone.min_col + 1
  }

  function deskTitle(desk: Desk): string {
    if (!desk.taken_by) return `Место ${desk.name} — свободно, нажмите чтобы забронировать`
    if (desk.taken_by.is_me) return `Место ${desk.name} — ваше, нажмите чтобы отменить`
    return `Место ${desk.name} — ${desk.taken_by.name}, ${desk.taken_by.team_name}`
  }

  function deskState(desk: Desk): string {
    if (desk.taken_by?.is_me) return 'mine'
    if (desk.taken_by?.is_teammate) return 'teammate'
    if (desk.taken_by) return 'taken'
    return 'free'
  }
</script>

<svelte:head>
  <title>Карта мест — Office Assistant</title>
</svelte:head>

<AppLayout>
  <PageHeader
    title="Карта мест"
    description="Свободно {freeTotal} из {deskTotal} мест. Нажмите на свободное место, чтобы забронировать."
  >
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/desks?date=${day}`} />
  </PageHeader>

  <!-- The map keeps its place: everything that appears and disappears — the
       booking, the schedule, the hints — lives in the sidebar. -->
  <div class="layout">
    <!-- On a phone what you have is more urgent than the whole floor, so the
         status comes first; on a wide screen it is the top of the sidebar. -->
    <div class="layout__status">{@render status()}</div>

    <div class="zones">
      {#each zones as zone (zone.id)}
        <Tile class={zone.is_mine ? 'zone zone--mine' : 'zone'}>
          <header class="zone__head">
            <h2 class="bx--type-productive-heading-01">
              {zone.name}
              {#if zone.is_mine}<span class="zone__mine">ваша команда</span>{/if}
            </h2>
            <span class="bx--type-caption-01">свободно {zone.free_count} из {zone.desks.length}</span>
          </header>

          <div class="desks" style="grid-template-columns: repeat({columns(zone)}, minmax(0, 1fr))">
            {#each zone.desks as desk (desk.id)}
              <div
                class="desk desk--{deskState(desk)}"
                class:desk--near={desk.is_near_target}
                style="grid-row: {desk.row - zone.min_row + 1}; grid-column: {desk.col - zone.min_col + 1}"
              >
                <!-- `light` is not decoration: a selectable tile is ui-01, the
                     same white as the zone tile it sits on, so without it the
                     free desks have no visible box at all. -->
                <SelectableTile
                  light
                  title={deskTitle(desk)}
                  bind:selected={selected[desk.id]}
                  disabled={!!desk.taken_by && !desk.taken_by.is_me}
                  on:click={(event) => chooseDesk(desk, event)}
                >
                  {#if desk.taken_by}
                    <span class="desk__initials">{initials(desk.taken_by.name)}</span>
                    <span class="desk__number bx--type-caption-01">{desk.name}</span>
                  {:else}
                    <span class="desk__number desk__number--free">{desk.name}</span>
                  {/if}

                  {#if desk.is_default}
                    <StarFilled size={16} class="desk__star" aria-label="Ваше обычное место" />
                  {/if}
                </SelectableTile>
              </div>
            {/each}
          </div>
        </Tile>
      {/each}
    </div>

    <aside class="layout__side">
      <div class="side">
        <div class="side__status">{@render status()}</div>

        {#if my_booking}
          <Tile>
            <h2 class="bx--type-productive-heading-01">Бронировать это место каждую</h2>
            <div class="weekdays">
              {#each weekdayOptions as option (option.value)}
                <Toggle
                  size="sm"
                  labelText={option.label}
                  labelA=""
                  labelB=""
                  toggled={scheduleDays.includes(option.value)}
                  on:toggle={(event) => toggleWeekday(option.value, event.detail.toggled)}
                />
              {/each}
            </div>
            <p class="side__hint bx--type-helper-text-01">
              {#if recurring && recurring.desk_id !== my_booking.desk_id}
                Сейчас постоянное место — {recurring.desk_name}
              {:else if scheduleDays.length > 0}
                Брони создаются на две недели вперёд
              {:else}
                Выберите дни, и место забронируется само
              {/if}
            </p>
          </Tile>
        {/if}

        {#if myZone && myZone.free_count === 0}
          <Tile>
            <p class="bx--type-body-long-01">
              В зоне {myZone.name}, где сидит ваша команда, свободных мест нет.
              {#if roomiest}Больше всего свободных — в зоне {roomiest.name}: {roomiest.free_count}.{/if}
            </p>
          </Tile>
        {/if}

        <Tile>
          <h2 class="bx--type-productive-heading-01">Обозначения</h2>
          <ul class="legend bx--type-caption-01">
            <li><span class="legend__swatch legend__swatch--free"></span> свободно</li>
            <li><span class="legend__swatch legend__swatch--mine"></span> ваше место</li>
            <li><span class="legend__swatch legend__swatch--teammate"></span> коллега по команде</li>
            <li><span class="legend__swatch legend__swatch--taken"></span> занято</li>
            <li><StarFilled size={16} aria-hidden="true" /> ваше обычное место</li>
          </ul>
        </Tile>
      </div>
    </aside>
  </div>

  <!-- One desk per person per day, so picking a second one moves the booking.
       Kept in the tree rather than wrapped in {#if}: Carbon returns focus to
       whatever opened it when its close transition ends, and an unmounted
       modal never gets that far. -->
  <Modal
    open={moveOpen}
    size="xs"
    selectorPrimaryFocus=".bx--btn--primary"
    modalHeading="Перенести бронь?"
    primaryButtonText="Перенести"
    secondaryButtonText="Оставить как есть"
    on:click:button--primary={confirmMove}
    on:click:button--secondary={cancelMove}
    on:close={cancelMove}
  >
    <p class="bx--type-body-long-01">
      На этот день у вас уже есть место {my_booking?.desk_name} в зоне {my_booking?.zone_name}.
      Если перенести, оно освободится, а вы займёте место {moveTo?.name}.
    </p>
  </Modal>

  <Toast message={error} />
</AppLayout>

{#snippet status()}
  <Tile>
    <h2 class="bx--type-productive-heading-01">Ваше место</h2>

    {#if my_booking}
      <p class="side__desk">
        <LocationFilled size={20} aria-hidden="true" />
        <span><strong>{my_booking.desk_name}</strong> · {my_booking.zone_name}</span>
      </p>
      <Button kind="tertiary" size="small" onclick={() => cancel(my_booking.id)}>Отменить бронь</Button>
    {:else}
      <p class="side__hint bx--type-body-long-01">На этот день не забронировано.</p>
      {#if default_desk && default_desk.free}
        <Button size="small" onclick={() => book(default_desk.id)}>
          Занять моё место {default_desk.name}
        </Button>
      {:else if default_desk}
        <p class="side__hint bx--type-helper-text-01">
          Обычное место {default_desk.name} занято — выберите другое на карте.
        </p>
      {/if}
    {/if}
  </Tile>

  {#if near}
    <Tile>
      <p class="bx--type-body-long-01">
        {#if nearZone && near.desk_name}
          <strong>{near.name}</strong> сидит на месте {near.desk_name} в зоне {nearZone.name} —
          оно обведено на карте.
          {#if nearZone.free_count > 0}
            Рядом свободно мест: {nearZone.free_count}.
          {:else}
            Свободных мест в этой зоне не осталось — выберите соседнюю.
          {/if}
        {:else}
          <strong>{near.name}</strong> не бронировал место на этот день.
        {/if}
      </p>
    </Tile>
  {/if}
{/snippet}

<style>
  .layout {
    margin-block-start: var(--cds-spacing-06);
    display: grid;
    gap: var(--cds-spacing-05);
  }

  .layout__status {
    display: grid;
    gap: var(--cds-spacing-05);
  }

  /* On a phone the sidebar is not dropped, it moves under the map: the weekday
     schedule and the legend live there and are the only way to reach them. */
  .layout__side {
    display: block;
  }

  .zones {
    display: grid;
    gap: var(--cds-spacing-05);
  }

  :global(.zone) {
    display: grid;
    gap: var(--cds-spacing-05);
    align-content: start;
  }

  /* The team's own zone is named by an edge, not by a wash of colour: colour on
     this screen has to stay free for desk states. */
  :global(.zone--mine) {
    box-shadow: inset var(--cds-spacing-02) 0 0 0 var(--cds-interactive-01);
  }

  .zone__head {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: space-between;
    gap: var(--cds-spacing-03);
  }

  .zone__head span {
    color: var(--cds-text-02);
  }

  .zone__mine {
    margin-inline-start: var(--cds-spacing-03);
    color: var(--cds-interactive-01);
    font-weight: 400;
  }

  .desks {
    display: grid;
    gap: var(--cds-spacing-03);
  }

  /* Carbon sizes a tile for a card: 8rem by 4rem. A desk on a floor plan is a
     square the size of a fingertip, so the map sets the box itself and keeps
     the component's states, focus ring and keyboard behaviour. */
  .desk :global(.bx--tile) {
    position: relative;
    min-width: 0;
    min-height: 0;
    aspect-ratio: 1;
    padding: var(--cds-spacing-02);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
  }

  .desk :global(.bx--tile-content) {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .desk :global(.bx--tile__checkmark) {
    inset-block-start: var(--cds-spacing-01);
    inset-inline-end: var(--cds-spacing-01);
  }

  .desk :global(.bx--tile__checkmark svg) {
    width: 1rem;
    height: 1rem;
  }

  /* text-03 on a tile is 2.2:1 — under the 3:1 that non-text graphics owe. */
  .desk :global(.desk__star) {
    position: absolute;
    inset-block-end: var(--cds-spacing-01);
    inset-inline-end: var(--cds-spacing-01);
    fill: var(--cds-text-02);
  }

  .desk--mine :global(.desk__star) {
    fill: var(--cds-interactive-01);
  }

  /* Carbon hovers a tile to hover-ui, which on this screen is the grey that
     already means "taken" — a free desk got darker than an occupied one under
     the cursor. The fill stays put and the hover says "clickable" with the
     interactive colour instead. Inset shadow, not outline: outline belongs to
     the focus ring and the two must not fight. */
  .desk--free :global(.bx--tile:hover) {
    background-color: var(--cds-ui-02);
    box-shadow: inset 0 0 0 1px var(--cds-interactive-01);
  }

  .desk--teammate :global(.bx--tile) {
    background-color: var(--cds-highlight);
    color: var(--cds-text-01);
  }

  /* Carbon paints a disabled tile's content in disabled-02 — 1.3:1 against the
     tile. That is the right colour for the label of a control you cannot use,
     and the wrong one here: the same tile carries who is sitting at the desk,
     which is information and has to stay readable. */
  .desk--taken :global(.bx--tile) {
    background-color: var(--cds-ui-03);
    color: var(--cds-text-02);
  }

  .desk--near :global(.bx--tile) {
    outline: var(--cds-spacing-01) solid var(--cds-interactive-01);
    outline-offset: var(--cds-spacing-01);
  }

  .desk__number {
    font-variant-numeric: tabular-nums;
  }

  .desk__number--free {
    font-weight: 600;
  }

  .desk__initials {
    font-weight: 600;
    font-size: 0.75rem;
  }

  .desk--taken .desk__number,
  .desk--teammate .desk__number {
    color: var(--cds-text-02);
  }

  .side {
    display: grid;
    gap: var(--cds-spacing-05);
    align-content: start;
  }

  .side :global(.bx--tile),
  .layout__status :global(.bx--tile) {
    display: grid;
    justify-items: start;
    gap: var(--cds-spacing-03);
  }

  .side__status {
    display: none;
    gap: var(--cds-spacing-05);
  }

  .side__desk {
    display: flex;
    align-items: center;
    gap: var(--cds-spacing-03);
  }

  .side__desk :global(svg) {
    flex-shrink: 0;
    fill: var(--cds-support-02);
  }

  .side__hint {
    color: var(--cds-text-02);
  }

  .weekdays {
    display: grid;
    gap: var(--cds-spacing-03);
    width: 100%;
  }

  .legend {
    display: grid;
    gap: var(--cds-spacing-03);
    color: var(--cds-text-02);
  }

  .legend li {
    display: flex;
    align-items: center;
    gap: var(--cds-spacing-03);
  }

  .legend :global(svg) {
    fill: var(--cds-text-03);
  }

  .legend__swatch {
    width: 1rem;
    height: 1rem;
    flex-shrink: 0;
    border: 1px solid var(--cds-ui-04);
  }

  /* Carbon draws a selected tile with a Gray 100 border, not an accent one. */
  .legend__swatch--mine {
    background-color: var(--cds-ui-02);
    border-color: var(--cds-ui-05);
  }

  .legend__swatch--free {
    background-color: var(--cds-ui-02);
  }

  .legend__swatch--teammate {
    background-color: var(--cds-highlight);
    border-color: var(--cds-highlight);
  }

  .legend__swatch--taken {
    background-color: var(--cds-ui-03);
    border-color: var(--cds-ui-03);
  }

  /* Two zones side by side from the medium breakpoint. */
  @media (min-width: 42rem) {
    .zones {
      grid-template-columns: 1fr 1fr;
    }
  }

  /* The sidebar moves beside the map where Carbon expects a two-column product
     layout, and the status moves up into it. */
  @media (min-width: 66rem) {
    .layout {
      grid-template-columns: minmax(0, 1fr) 18rem;
      align-items: start;
      gap: var(--cds-spacing-06);
    }

    .layout__status {
      display: none;
    }

    .side__status {
      display: grid;
    }
  }
</style>
