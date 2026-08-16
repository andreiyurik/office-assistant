<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import type { CurrentUser } from '@/types'

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
    taken_by: TakenBy | null
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
    current_user,
    selected_date,
    days,
    zones,
    my_booking,
    default_desk,
    errors = {},
  }: {
    current_user: CurrentUser
    selected_date: string
    days: string[]
    zones: Zone[]
    my_booking: { id: number; desk_name: string; zone_name: string } | null
    default_desk: { id: number; name: string; zone_name: string; free: boolean } | null
    errors?: Record<string, string[] | string>
  } = $props()

  const myZone = $derived(zones.find((zone) => zone.is_mine))
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
      return 'bg-primary/10 text-foreground border-primary/40 font-medium cursor-default'
    }
    if (desk.taken_by) {
      return 'bg-muted/60 text-muted-foreground border-transparent cursor-default'
    }
    return 'bg-background hover:border-primary hover:bg-primary/5 cursor-pointer'
  }
</script>

<svelte:head>
  <title>Карта мест — Office Assistant</title>
</svelte:head>

<AppLayout {current_user}>
  <h1 class="text-xl font-semibold tracking-tight">Карта мест</h1>

  <div class="mt-4">
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/desks?date=${day}`} />
  </div>

  <div
    class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg border px-4 py-2.5 text-sm"
  >
    {#if my_booking}
      <span>
        Ваше место: <span class="font-medium">{my_booking.desk_name}</span> · {my_booking.zone_name}
      </span>
      <button
        type="button"
        onclick={() => cancel(my_booking.id)}
        class="font-medium underline underline-offset-4"
      >
        Отменить бронь
      </button>
    {:else}
      <span class="text-muted-foreground">Место на этот день не забронировано.</span>
      {#if default_desk && default_desk.free}
        <button
          type="button"
          onclick={() => book(default_desk.id)}
          class="rounded-md bg-primary px-3 py-1.5 font-medium text-primary-foreground transition-colors hover:bg-primary/80"
        >
          Занять моё место {default_desk.name}
        </button>
      {:else if default_desk}
        <span class="text-muted-foreground">
          Ваше обычное место {default_desk.name} занято — выберите другое на карте.
        </span>
      {/if}
    {/if}
  </div>

  {#if bookingError()}
    <p class="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
      {bookingError()}
    </p>
  {/if}

  {#if myZone && myZone.free_count === 0}
    <p class="mt-3 rounded-md bg-muted px-3 py-2 text-sm">
      В зоне {myZone.name}, где сидит ваша команда, свободных мест нет.
      {#if roomiest}Больше всего свободных — в зоне {roomiest.name}: {roomiest.free_count}.{/if}
    </p>
  {/if}

  <div class="mt-4 flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded border bg-background"></span> свободно
    </span>
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded bg-primary"></span> ваше место
    </span>
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded border border-primary/40 bg-primary/10"></span> коллега по команде
    </span>
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded bg-muted/60"></span> занято
    </span>
    <span class="ml-auto">Нажмите на свободное место, чтобы забронировать</span>
  </div>

  <div class="mt-4 grid gap-4 md:grid-cols-2">
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
              )}"
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
</AppLayout>
