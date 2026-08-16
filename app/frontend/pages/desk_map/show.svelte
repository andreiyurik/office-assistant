<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
  import Toast from '@/lib/components/Toast.svelte'
  import { Button } from '@/lib/components/ui/button'
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

  const error = $derived(firstError(errors))

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
      return 'bg-primary text-primary-foreground border-primary shadow-sm cursor-pointer hover:bg-primary/90'
    }
    if (desk.taken_by?.is_teammate) {
      return 'bg-primary/10 text-primary border-primary/40 font-medium cursor-default'
    }
    if (desk.taken_by) {
      return 'bg-muted/60 text-muted-foreground/70 border-transparent cursor-default'
    }
    return 'bg-background hover:border-primary/60 hover:bg-primary/5 hover:shadow-sm cursor-pointer'
  }

  const freeTotal = $derived(zones.reduce((sum, zone) => sum + zone.free_count, 0))
  const deskTotal = $derived(zones.reduce((sum, zone) => sum + zone.desks.length, 0))
</script>

<svelte:head>
  <title>Карта мест — Office Assistant</title>
</svelte:head>

<AppLayout>
  <PageHeader title="Карта мест" description="Свободно {freeTotal} из {deskTotal} мест. Нажмите на свободное место, чтобы забронировать.">
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/desks?date=${day}`} />
  </PageHeader>

  <!-- The map keeps its place: everything that appears and disappears — the
       booking, the schedule, the hints — lives in the sidebar or floats above. -->
  <div class="mt-6 flex flex-col items-start gap-6 lg:flex-row">
    <!-- On a phone the status card comes before the map: what you have is
         more urgent than the whole floor. On a wide screen it is the sidebar. -->
    <div class="w-full lg:hidden">{@render status()}</div>

    <div class="w-full min-w-0 flex-1">
      <div class="grid gap-4 md:grid-cols-2">
        {#each zones as zone (zone.id)}
          <section
            class="rounded-xl border bg-card p-4 {zone.is_mine
              ? 'border-primary/30 bg-primary/[0.03]'
              : ''}"
          >
            <header class="mb-3 flex items-center justify-between gap-2">
              <h2 class="flex items-center gap-2 text-sm font-semibold">
                {zone.name}
                {#if zone.is_mine}
                  <span class="rounded-full bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
                    ваша команда
                  </span>
                {/if}
              </h2>
              <span class="text-xs text-muted-foreground tabular-nums">
                свободно {zone.free_count} из {zone.desks.length}
              </span>
            </header>

            <div class="grid gap-2" style="grid-template-columns: repeat({columns(zone)}, minmax(0, 1fr))">
              {#each zone.desks as desk (desk.id)}
                <button
                  type="button"
                  title={deskTitle(desk)}
                  disabled={!!desk.taken_by && !desk.taken_by.is_me}
                  onclick={() => (desk.taken_by?.is_me ? cancel(my_booking!.id) : book(desk.id))}
                  style="grid-row: {desk.row - zone.min_row + 1}; grid-column: {desk.col - zone.min_col + 1}"
                  class="relative flex aspect-square flex-col items-center justify-center rounded-lg border text-sm transition-all focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:outline-none {deskClasses(
                    desk,
                  )} {desk.is_near_target ? 'ring-2 ring-primary ring-offset-2' : ''}"
                >
                  {#if desk.taken_by}
                    <span class="text-xs font-semibold">{initials(desk.taken_by.name)}</span>
                    <span class="text-[10px] opacity-70 tabular-nums">{desk.name}</span>
                  {:else}
                    <span class="font-medium tabular-nums">{desk.name}</span>
                  {/if}

                  {#if desk.is_default}
                    <span class="absolute top-1 right-1.5 text-[10px] leading-none opacity-80" title="Ваше обычное место">★</span>
                  {/if}
                </button>
              {/each}
            </div>
          </section>
        {/each}
      </div>
    </div>

    <aside class="w-full shrink-0 space-y-3 lg:w-72">
      <div class="hidden lg:block">{@render status()}</div>

      {#if my_booking}
        <section class="rounded-xl border bg-card p-4">
          <h2 class="text-sm font-semibold">Бронировать каждую</h2>
          <div class="mt-2 flex flex-wrap gap-1.5" role="group" aria-label="Дни недели">
            {#each weekdayOptions as option (option.value)}
              <button
                type="button"
                aria-pressed={scheduleDays.includes(option.value)}
                onclick={() => toggleWeekday(option.value)}
                class="rounded-full border px-3 py-1 text-xs font-medium transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none {scheduleDays.includes(
                  option.value,
                )
                  ? 'border-primary bg-primary text-primary-foreground'
                  : 'hover:border-primary/40 hover:bg-primary/5'}"
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

      {#if myZone && myZone.free_count === 0}
        <section class="rounded-xl border bg-muted/40 p-4 text-sm">
          В зоне {myZone.name}, где сидит ваша команда, свободных мест нет.
          {#if roomiest}Больше всего свободных — в зоне {roomiest.name}: {roomiest.free_count}.{/if}
        </section>
      {/if}

      <section class="space-y-2 rounded-xl border bg-card p-4 text-xs text-muted-foreground">
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded border bg-background"></span> свободно
        </span>
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded bg-primary"></span> ваше место
        </span>
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded border border-primary/40 bg-primary/10"></span>
          коллега по команде
        </span>
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded bg-muted"></span> занято
        </span>
        <span class="flex items-center gap-2">
          <span class="flex size-3.5 items-center justify-center rounded border text-[9px]">★</span> ваше обычное место
        </span>
      </section>
    </aside>
  </div>

  <Toast message={error} />
</AppLayout>

{#snippet status()}
  <div class="space-y-3">
    <section class="rounded-xl border bg-card p-4">
      <h2 class="text-sm font-semibold">Ваше место</h2>

      {#if my_booking}
        <p class="mt-2 flex items-center gap-2 text-sm">
          <span class="size-2 rounded-full bg-success" aria-hidden="true"></span>
          <span class="font-medium">{my_booking.desk_name}</span> · {my_booking.zone_name}
        </p>
        <Button variant="outline" size="sm" class="mt-3" onclick={() => cancel(my_booking.id)}>
          Отменить бронь
        </Button>
      {:else}
        <p class="mt-1 text-sm text-muted-foreground">На этот день не забронировано.</p>
        {#if default_desk && default_desk.free}
          <Button size="sm" class="mt-3 w-full" onclick={() => book(default_desk.id)}>
            Занять моё место {default_desk.name}
          </Button>
        {:else if default_desk}
          <p class="mt-2 text-xs text-muted-foreground">
            Обычное место {default_desk.name} занято — выберите другое на карте.
          </p>
        {/if}
      {/if}
    </section>
    {#if near}
      <section class="rounded-xl border border-primary/20 bg-primary/5 p-4 text-sm">
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
  </div>
{/snippet}
