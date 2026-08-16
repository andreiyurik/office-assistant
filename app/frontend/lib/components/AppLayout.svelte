<script lang="ts">
  import type { Snippet } from 'svelte'
  import { Link, page, router } from '@inertiajs/svelte'
  import { initials, time } from '@/lib/format'
  import { Button, buttonVariants } from '@/lib/components/ui/button'
  import BrandMark from '@/lib/components/BrandMark.svelte'
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

  function releaseIn(iso: string): string {
    const minutes = Math.round((new Date(iso).getTime() - Date.now()) / 60000)
    return minutes <= 0 ? 'вот-вот' : `через ${minutes} мин`
  }

  function checkIn(id: number): void {
    router.post(`/room_bookings/${id}/check_in`, {}, { preserveScroll: true })
  }
</script>

<div class="min-h-screen bg-background text-foreground">
  <header class="sticky top-0 z-10 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/80">
    <div class="mx-auto max-w-6xl px-4">
      <div class="flex h-14 items-center justify-between gap-3">
        <div class="flex min-w-0 items-center gap-6">
          <Link href="/" class="flex shrink-0 items-center gap-2 rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none">
            <BrandMark />
            <span class="text-sm font-semibold tracking-tight">Office Assistant</span>
          </Link>

          <!-- Desktop: pills next to the brand. Phone: the tab row below. -->
          <nav class="hidden items-center gap-1 md:flex" aria-label="Разделы">
            {#each links as link (link.href)}
              <Link
                href={link.href}
                aria-current={isActive(link.href) ? 'page' : undefined}
                class="rounded-md px-3 py-1.5 text-sm font-medium transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none {isActive(
                  link.href,
                )
                  ? 'bg-primary/10 text-primary'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'}"
              >
                {link.label}
              </Link>
            {/each}
          </nav>
        </div>

        <div class="flex items-center gap-2 sm:gap-3">
          <!-- The check-in prompt sits in the header row that already exists, so
               the page below never moves when it appears. -->
          {#if pending}
            <Button
              size="sm"
              title="Переговорная {pending.room_name} в {time(pending.starts_at)}. Подтвердите, иначе слот освободится {releaseIn(
                pending.releases_at,
              )}."
              onclick={() => checkIn(pending.id)}
            >
              <span class="relative flex size-2">
                <span class="absolute inline-flex size-full animate-ping rounded-full bg-primary-foreground/70"></span>
                <span class="relative inline-flex size-2 rounded-full bg-primary-foreground"></span>
              </span>
              Отметиться
              <span class="hidden font-normal opacity-80 lg:inline">
                · {pending.room_name}, {time(pending.starts_at)}
              </span>
            </Button>
          {/if}

          <div class="flex items-center gap-2">
            <span
              class="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary"
              aria-hidden="true"
            >
              {initials(user.name)}
            </span>
            <div class="hidden leading-tight sm:block">
              <div class="text-sm font-medium">{user.name}</div>
              <div class="text-xs text-muted-foreground">{user.team_name}</div>
            </div>
          </div>

          <Link
            href="/session"
            method="delete"
            as="button"
            class={buttonVariants({ variant: 'ghost', size: 'sm' }) + ' text-muted-foreground'}
          >
            Выйти
          </Link>
        </div>
      </div>

      <nav class="-mx-4 grid grid-cols-3 border-t md:hidden" aria-label="Разделы">
        {#each links as link (link.href)}
          <Link
            href={link.href}
            aria-current={isActive(link.href) ? 'page' : undefined}
            class="-mb-px border-b-2 px-2 py-2.5 text-center text-sm font-medium transition-colors {isActive(
              link.href,
            )
              ? 'border-primary text-primary'
              : 'border-transparent text-muted-foreground hover:text-foreground'}"
          >
            {link.label}
          </Link>
        {/each}
      </nav>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-4 py-6 md:py-8">
    {@render children()}
  </main>
</div>
