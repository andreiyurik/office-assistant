<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import Toast from '@/lib/components/Toast.svelte'

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
    { value: 1, label: 'Пн' },
    { value: 2, label: 'Вт' },
    { value: 3, label: 'Ср' },
    { value: 4, label: 'Чт' },
    { value: 5, label: 'Пт' },
  ]

  // The days are shown as chosen only when the schedule is about the desk on
  // screen — otherwise the person would see ticks next to another desk.
  const scheduleDays = $derived(
    recurring && my_booking && recurring.desk_id === my_booking.desk_id ? recurring.weekdays : [],
  )

  function toggleWeekday(day: number): void {
    if (!my_booking) return

    const next = scheduleDays.includes(day)
      ? scheduleDays.filter((chosen) => chosen !== day)
      : [...scheduleDays, day].sort()

    router.patch(
      '/recurring_schedule',
      { resource_id: my_booking.desk_id, weekdays: next, date: selected_date },
      { preserveScroll: true },
    )
  }

  const myZone = $derived(zones.find((zone) => zone.is_mine))
  const nearZone = $derived(near ? zones.find((zone) => zone.id === near.zone_id) : undefined)
  const roomiest = $derived(
    zones
      .filter((zone) => !zone.is_mine && zone.free_count > 0)
      .sort((a, b) => b.free_count - a.free_count)[0],
  )

  function bookingError(): string | null {
    const value = errors.booking
    if (!value) return null
    return Array.isArray(value) ? value[0] : value
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

  function initials(name: string): string {
    return name
      .split(' ')
      .slice(0, 2)
      .map((part) => part[0])
      .join('')
  }

  function columns(zone: Zone): number {
    return Math.max(...zone.desks.map((desk) => desk.col)) - zone.min_col + 1
  }

  function deskTitle(desk: Desk): string {
    if (!desk.taken_by) return `Место ${desk.name} — свободно, нажмите чтобы забронировать`
    if (desk.taken_by.is_me) return `Место ${desk.name} — ваше, нажмите чтобы отменить`
    return `Место ${desk.name} — ${desk.taken_by.name}, ${desk.taken_by.team_name}`
  }

  function deskClasses(desk: Desk): string {
    if (desk.taken_by?.is_me) {
      return 'bg-primary text-primary-foreground border-primary cursor-pointer'
    }
    if (desk.taken_by?.is_teammate) {
      return 'bg-primary/15 text-foreground border-primary/60 ring-1 ring-primary/30 font-medium cursor-default'
    }
    if (desk.taken_by) {
      return 'bg-muted/50 text-muted-foreground/70 border-transparent cursor-default'
    }
    return 'bg-background hover:border-primary hover:bg-primary/5 cursor-pointer'
  }
</script>

<svelte:head>
  <title>Карта мест — Office Assistant</title>
</svelte:head>

<AppLayout>
  <div class="flex flex-wrap items-end justify-between gap-3">
    <h1 class="text-xl font-semibold tracking-tight">Карта мест</h1>
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/desks?date=${day}`} />
  </div>

  <!-- The map keeps its place: everything that appears and disappears — the
       booking, the schedule, the hints — lives in the sidebar or floats above. -->
  <div class="mt-4 flex flex-col items-start gap-4 md:flex-row">
    <div class="w-full min-w-0 flex-1">
    <div class="grid gap-4 md:grid-cols-2">
      {#each zones as zone (zone.id)}
        <section
          class="rounded-xl border p-3 {zone.is_mine ? 'border-foreground/20 bg-muted/30' : ''}"
        >
          <header class="mb-3 flex items-center justify-between gap-2">
            <h2 class="text-sm font-medium">
              {zone.name}
              {#if zone.is_mine}
                <span class="ml-1.5 rounded-full bg-foreground px-2 py-0.5 text-xs text-background">
                  ваша команда
                </span>
              {/if}
            </h2>
            <span class="text-xs text-muted-foreground">
              свободно {zone.free_count} из {zone.desks.length}
            </span>
          </header>

          <div class="grid gap-1.5" style="grid-template-columns: repeat({columns(zone)}, minmax(0, 1fr))">
            {#each zone.desks as desk (desk.id)}
              <button
                type="button"
                title={deskTitle(desk)}
                disabled={!!desk.taken_by && !desk.taken_by.is_me}
                onclick={() => (desk.taken_by?.is_me ? cancel(my_booking!.id) : book(desk.id))}
                style="grid-row: {desk.row - zone.min_row + 1}; grid-column: {desk.col - zone.min_col + 1}"
                class="relative flex aspect-square flex-col items-center justify-center rounded-lg border text-sm transition-colors {deskClasses(
                  desk,
                )} {desk.is_near_target ? 'ring-2 ring-foreground ring-offset-2' : ''}"
              >
                {#if desk.taken_by}
                  <span class="text-xs font-medium">{initials(desk.taken_by.name)}</span>
                  <span class="text-[10px] opacity-70">{desk.name}</span>
                {:else}
                  <span class="font-medium">{desk.name}</span>
                {/if}

                {#if desk.is_default}
                  <span class="absolute top-0.5 right-1 text-[10px] leading-none opacity-70">★</span>
                {/if}
              </button>
            {/each}
          </div>
        </section>
      {/each}
    </div>
    </div>

    <aside class="w-full shrink-0 space-y-3 md:w-64">
      <section class="rounded-lg border p-3">
        <h2 class="text-sm font-medium">Ваше место</h2>

        {#if my_booking}
          <p class="mt-1 text-sm">
            <span class="font-medium">{my_booking.desk_name}</span> · {my_booking.zone_name}
          </p>
          <button
            type="button"
            onclick={() => cancel(my_booking.id)}
            class="mt-2 text-xs text-muted-foreground underline underline-offset-4 hover:text-foreground"
          >
            Отменить бронь
          </button>
        {:else}
          <p class="mt-1 text-xs text-muted-foreground">На этот день не забронировано.</p>
          {#if default_desk && default_desk.free}
            <button
              type="button"
              onclick={() => book(default_desk.id)}
              class="mt-2 w-full rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/80"
            >
              Занять моё место {default_desk.name}
            </button>
          {:else if default_desk}
            <p class="mt-2 text-xs text-muted-foreground">
              Обычное место {default_desk.name} занято — выберите другое на карте.
            </p>
          {/if}
        {/if}
      </section>

      {#if my_booking}
        <section class="rounded-lg border p-3">
          <h2 class="text-sm font-medium">Бронировать каждую</h2>
          <div class="mt-2 flex flex-wrap gap-1">
            {#each weekdayOptions as option (option.value)}
              <button
                type="button"
                onclick={() => toggleWeekday(option.value)}
                class="rounded-full border px-2.5 py-1 text-xs transition-colors {scheduleDays.includes(
                  option.value,
                )
                  ? 'border-foreground bg-foreground text-background'
                  : 'hover:bg-muted'}"
              >
                {option.label}
              </button>
            {/each}
          </div>
          <p class="mt-2 text-xs text-muted-foreground">
            {#if recurring && recurring.desk_id !== my_booking.desk_id}
              Сейчас постоянное место — {recurring.desk_name}
            {:else if scheduleDays.length > 0}
              Брони создаются на две недели вперёд
            {:else}
              Выберите дни, и место забронируется само
            {/if}
          </p>
        </section>
      {/if}

      {#if near}
        <section class="rounded-lg border bg-muted/40 p-3 text-xs">
          {#if nearZone && near.desk_name}
            <span class="font-medium">{near.name}</span> сидит на месте {near.desk_name} в зоне
            {nearZone.name} — оно обведено на карте.
            {#if nearZone.free_count > 0}
              Рядом свободно мест: {nearZone.free_count}.
            {:else}
              Свободных мест в этой зоне не осталось — выберите соседнюю.
            {/if}
          {:else}
            <span class="font-medium">{near.name}</span> не бронировал место на этот день.
          {/if}
        </section>
      {/if}

      {#if myZone && myZone.free_count === 0}
        <section class="rounded-lg border bg-muted/40 p-3 text-xs">
          В зоне {myZone.name}, где сидит ваша команда, свободных мест нет.
          {#if roomiest}Больше всего свободных — в зоне {roomiest.name}: {roomiest.free_count}.{/if}
        </section>
      {/if}

      <section class="space-y-1.5 rounded-lg border p-3 text-xs text-muted-foreground">
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded border bg-background"></span> свободно
        </span>
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded bg-primary"></span> ваше место
        </span>
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded border border-primary/60 bg-primary/15"></span>
          коллега по команде
        </span>
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded bg-muted/50"></span> занято
        </span>
        <p>Нажмите на свободное место, чтобы забронировать.</p>
      </section>
    </aside>
  </div>

  <Toast message={bookingError()} />
</AppLayout>
