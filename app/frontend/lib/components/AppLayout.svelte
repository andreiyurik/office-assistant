<script lang="ts">
  import type { Snippet } from 'svelte'
  import { Link, page, router } from '@inertiajs/svelte'
  import type { CurrentUser, PendingCheckIn } from '@/types'

  let { children }: { children: Snippet } = $props()

  // Both come from the shared props every controller sends.
  const user = $derived(page.props.current_user as CurrentUser)
  const pending = $derived(page.props.pending_check_in as PendingCheckIn | null)

  const links = [
    { href: '/', label: 'Кто в офисе' },
    { href: '/desks', label: 'Карта мест' },
    { href: '/rooms', label: 'Переговорные' },
  ]

  function isActive(href: string): boolean {
    const path = page.url.split('?')[0]
    return href === '/' ? path === '/' : path.startsWith(href)
  }

  function time(iso: string): string {
    return new Date(iso).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
  }

  function releaseIn(iso: string): string {
    const minutes = Math.round((new Date(iso).getTime() - Date.now()) / 60000)
    return minutes <= 0 ? 'вот-вот' : `через ${minutes} мин`
  }

  function checkIn(id: number): void {
    router.post(`/room_bookings/${id}/check_in`, {}, { preserveScroll: true })
  }
</script>

<div class="min-h-screen bg-background text-foreground">
  <header class="sticky top-0 z-10 border-b bg-background/95 backdrop-blur">
    <div class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-2.5">
      <nav class="flex items-center gap-1">
        <span class="mr-2 hidden text-sm font-semibold tracking-tight sm:inline">Office Assistant</span>
        {#each links as link (link.href)}
          <Link
            href={link.href}
            class="rounded-md px-3 py-1.5 text-sm font-medium transition-colors {isActive(link.href)
              ? 'bg-secondary text-secondary-foreground'
              : 'text-muted-foreground hover:text-foreground'}"
          >
            {link.label}
          </Link>
        {/each}
      </nav>

      <div class="flex items-center gap-3">
        <div class="text-right leading-tight">
          <div class="text-sm font-medium">{user.name}</div>
          <div class="text-xs text-muted-foreground">{user.team_name}</div>
        </div>
        <Link
          href="/session"
          method="delete"
          as="button"
          class="rounded-md px-2 py-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          Выйти
        </Link>
      </div>
    </div>

    {#if pending}
      <div class="border-t bg-primary/10">
        <div
          class="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-2 text-sm"
        >
          <span>
            Переговорная {pending.room_name} в {time(pending.starts_at)} — подтвердите, что встреча
            идёт. Иначе слот освободится {releaseIn(pending.releases_at)}.
          </span>
          <button
            type="button"
            onclick={() => checkIn(pending.id)}
            class="rounded-md bg-primary px-3 py-1.5 font-medium text-primary-foreground transition-colors hover:bg-primary/80"
          >
            Отметиться
          </button>
        </div>
      </div>
    {/if}
  </header>

  <main class="mx-auto max-w-6xl px-4 py-6">
    {@render children()}
  </main>
</div>
