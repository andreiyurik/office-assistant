<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'

  type Cell = {
    state: 'free' | 'taken' | 'mine'
    person: string | null
    checked_in: boolean
    continuation: boolean
    released: boolean
    past: boolean
  }

  type Room = {
    id: number
    name: string
    capacity: number
    cells: Cell[]
  }

  type Meeting = {
    id: number
    room_name: string
    starts_at: string
    ends_at: string
    checked_in: boolean
    can_check_in: boolean
    check_in_opens_at: string
  }

  let {
    selected_date,
    days,
    slots,
    rooms,
    my_meetings,
    errors = {},
  }: {
    selected_date: string
    days: string[]
    slots: string[]
    rooms: Room[]
    my_meetings: Meeting[]
    errors?: Record<string, string[] | string>
  } = $props()

  const durations = [
    { slots: 1, label: '30 минут' },
    { slots: 2, label: '1 час' },
    { slots: 3, label: '1,5 часа' },
  ]

  let duration = $state(1)
  let hovered: { roomId: number; index: number } | null = $state(null)

  // The slot happening right now, so the eye lands on it first. Negative on any
  // day other than today.
  const nowIndex = $derived(
    slots.findIndex((slot) => {
      const start = new Date(slot).getTime()
      return Date.now() >= start && Date.now() < start + 30 * 60 * 1000
    }),
  )

  function time(iso: string): string {
    return new Date(iso).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
  }

  function bookingError(): string | null {
    const value = errors.booking
    if (!value) return null
    return Array.isArray(value) ? value[0] : value
  }

  // A slot can be taken only if the whole chosen duration fits after it.
  function canBook(room: Room, index: number): boolean {
    for (let step = 0; step < duration; step++) {
      const cell = room.cells[index + step]
      if (!cell || cell.state !== 'free' || cell.past) return false
    }
    return true
  }

  function isPreviewed(room: Room, index: number): boolean {
    if (!hovered || hovered.roomId !== room.id) return false
    return index >= hovered.index && index < hovered.index + duration
  }

  function book(room: Room, index: number): void {
    if (!canBook(room, index)) return
    router.post(
      '/room_bookings',
      { resource_id: room.id, starts_at: slots[index], slots: duration },
      { preserveScroll: true },
    )
  }

  function checkIn(meeting: Meeting): void {
    router.post(`/room_bookings/${meeting.id}/check_in`, {}, { preserveScroll: true })
  }

  function cancel(meeting: Meeting): void {
    router.delete(`/room_bookings/${meeting.id}`, { preserveScroll: true })
  }

  function cellClasses(room: Room, index: number): string {
    const cell = room.cells[index]

    if (cell.state === 'mine') {
      return cell.checked_in
        ? 'bg-primary text-primary-foreground'
        : 'bg-primary/80 text-primary-foreground'
    }
    if (cell.state === 'taken') return 'bg-muted text-muted-foreground'
    if (cell.past) return 'bg-muted/50 text-muted-foreground/60'
    if (isPreviewed(room, index)) return 'bg-primary/20'
    if (canBook(room, index)) return 'bg-background hover:bg-primary/10 cursor-pointer'
    return 'bg-background text-muted-foreground/60'
  }

  function cellTitle(room: Room, index: number): string {
    const cell = room.cells[index]
    const at = `${room.name}, ${time(slots[index])}`

    if (cell.state === 'mine') return `${at} — ваша бронь`
    if (cell.state === 'taken') return `${at} — ${cell.person}`
    if (cell.past) return `${at} — время прошло`
    if (cell.released) return `${at} — бронь освободилась автоматически, слот снова свободен`
    if (!canBook(room, index)) return `${at} — выбранная длительность сюда не помещается`
    return `${at} — свободно, нажмите чтобы забронировать`
  }
</script>

<svelte:head>
  <title>Переговорные — Office Assistant</title>
</svelte:head>

<AppLayout>
  <h1 class="text-xl font-semibold tracking-tight">Переговорные</h1>

  <div class="mt-4">
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/rooms?date=${day}`} />
  </div>

  {#if my_meetings.length > 0}
    <ul class="mt-3 divide-y rounded-lg border">
      {#each my_meetings as meeting (meeting.id)}
        <li class="flex flex-wrap items-center justify-between gap-3 px-4 py-2.5 text-sm">
          <span>
            <span class="font-medium">{meeting.room_name}</span>
            · {time(meeting.starts_at)}–{time(meeting.ends_at)}
            {#if meeting.checked_in}
              <span class="ml-1.5 text-muted-foreground">вы отметились</span>
            {/if}
          </span>

          <span class="flex items-center gap-3">
            {#if !meeting.checked_in}
              {#if meeting.can_check_in}
                <button
                  type="button"
                  onclick={() => checkIn(meeting)}
                  class="rounded-md bg-primary px-3 py-1.5 font-medium text-primary-foreground transition-colors hover:bg-primary/80"
                >
                  Отметиться
                </button>
              {:else}
                <span class="text-xs text-muted-foreground">
                  Отметиться можно с {time(meeting.check_in_opens_at)}
                </span>
              {/if}
            {/if}
            <button
              type="button"
              onclick={() => cancel(meeting)}
              class="text-muted-foreground underline underline-offset-4 hover:text-foreground"
            >
              Отменить
            </button>
          </span>
        </li>
      {/each}
    </ul>
  {/if}

  {#if bookingError()}
    <p class="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
      {bookingError()}
    </p>
  {/if}

  <div class="mt-4 flex flex-wrap items-center gap-3 text-sm">
    <span class="text-muted-foreground">Бронирую на</span>
    {#each durations as option (option.slots)}
      <button
        type="button"
        onclick={() => (duration = option.slots)}
        class="rounded-full border px-3 py-1 transition-colors {duration === option.slots
          ? 'border-foreground bg-foreground text-background'
          : 'hover:bg-muted'}"
      >
        {option.label}
      </button>
    {/each}
    <span class="ml-auto text-xs text-muted-foreground">
      Нажмите на свободный слот, чтобы забронировать
    </span>
  </div>

  <div class="mt-4 overflow-x-auto rounded-lg border">
    <table class="w-full border-collapse text-sm">
      <thead>
        <tr class="border-b">
          <th class="w-16 px-2 py-2 text-left text-xs font-medium text-muted-foreground">Время</th>
          {#each rooms as room (room.id)}
            <th class="border-l px-2 py-2 text-left font-medium">
              {room.name}
              <span class="ml-1 text-xs font-normal text-muted-foreground">{room.capacity} мест</span>
            </th>
          {/each}
        </tr>
      </thead>
      <tbody>
        {#each slots as slot, index (slot)}
          <tr class="border-b last:border-b-0">
            <td
              class="px-2 py-0 text-xs tabular-nums {index === nowIndex
                ? 'font-semibold text-foreground'
                : 'text-muted-foreground'}"
            >
              {index === nowIndex || index % 2 === 0 ? time(slot) : ''}
            </td>
            {#each rooms as room (room.id)}
              <td class="border-l p-0">
                <button
                  type="button"
                  title={cellTitle(room, index)}
                  disabled={!canBook(room, index)}
                  onclick={() => book(room, index)}
                  onmouseenter={() => (hovered = { roomId: room.id, index })}
                  onmouseleave={() => (hovered = null)}
                  class="flex h-8 w-full items-center gap-1.5 px-2 text-left text-xs transition-colors {cellClasses(
                    room,
                    index,
                  )}"
                >
                  {#if room.cells[index].continuation}
                    <!-- the meeting started in the slot above, drawn as one block -->
                  {:else if room.cells[index].state === 'mine'}
                    <span class="font-medium">
                      {room.cells[index].checked_in ? '✓ вы' : 'вы'}
                    </span>
                  {:else if room.cells[index].state === 'taken'}
                    <span class="truncate">{room.cells[index].person}</span>
                  {:else if room.cells[index].released}
                    <span class="text-[10px] text-muted-foreground">освободилось</span>
                  {/if}
                </button>
              </td>
            {/each}
          </tr>
        {/each}
      </tbody>
    </table>
  </div>

  <div class="mt-3 flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded border bg-background"></span> свободно
    </span>
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded bg-primary"></span> ваша бронь
    </span>
    <span class="flex items-center gap-1.5">
      <span class="size-3 rounded bg-muted"></span> занято
    </span>
    <span>«освободилось» — бронь сняли автоматически, никто не отметился</span>
  </div>
</AppLayout>
