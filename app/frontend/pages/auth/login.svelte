<script lang="ts">
  import { Form } from '@inertiajs/svelte'
  import { firstError } from '@/lib/format'
  import { Button } from '@/lib/components/ui/button'
  import BrandMark from '@/lib/components/BrandMark.svelte'
  import UsersThreeIcon from 'phosphor-svelte/lib/UsersThreeIcon'
  import SquaresFourIcon from 'phosphor-svelte/lib/SquaresFourIcon'
  import CalendarBlankIcon from 'phosphor-svelte/lib/CalendarBlankIcon'

  let { errors = {} }: { errors?: Record<string, string[] | string> } = $props()

  const error = $derived(firstError(errors))

  // What the product does, in the order a person meets it. Shown on the wide
  // layout only; the form is the whole story on a phone.
  const points = [
    { icon: UsersThreeIcon, title: 'Кто сегодня в офисе', text: 'Список на неделю вперёд, по командам.' },
    { icon: SquaresFourIcon, title: 'Место рядом с командой', text: 'Карта этажа, бронь в один клик, своё место каждую неделю.' },
    { icon: CalendarBlankIcon, title: 'Переговорная без накладок', text: 'Слоты по полчаса; забытая бронь освобождается сама.' },
  ]
</script>

<svelte:head>
  <title>Вход — Office Assistant</title>
</svelte:head>

<div class="grid min-h-screen lg:grid-cols-[1.1fr_1fr]">
  <!-- Brand panel: dark, quiet, with a faint floor-plan grid behind the text. -->
  <aside
    class="relative hidden overflow-hidden bg-[oklch(0.2_0.03_265)] text-white lg:flex lg:flex-col lg:justify-between lg:p-12"
    aria-hidden="true"
  >
    <div
      class="pointer-events-none absolute inset-0 opacity-[0.18]"
      style="background-image: radial-gradient(oklch(1 0 0 / 0.55) 1px, transparent 1px); background-size: 28px 28px;"
    ></div>
    <div
      class="pointer-events-none absolute -top-40 -right-40 size-[34rem] rounded-full bg-[radial-gradient(closest-side,oklch(0.55_0.19_262/0.55),transparent)]"
    ></div>

    <div class="relative flex items-center gap-3">
      <BrandMark class="size-9" />
      <span class="text-lg font-semibold tracking-tight">Office Assistant</span>
    </div>

    <div class="relative max-w-md">
      <h2 class="text-3xl leading-tight font-semibold tracking-tight text-balance">
        Гибридный офис, в котором понятно, где и с кем ты окажешься.
      </h2>
      <ul class="mt-10 space-y-6">
        {#each points as point (point.title)}
          <li class="flex gap-4">
            <span class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-white/10">
              <point.icon size={20} weight="regular" />
            </span>
            <span>
              <span class="block font-medium">{point.title}</span>
              <span class="mt-0.5 block text-sm text-white/65">{point.text}</span>
            </span>
          </li>
        {/each}
      </ul>
    </div>

    <p class="relative text-xs text-white/45">Внутренний сервис. Вход по рабочей почте.</p>
  </aside>

  <!-- Form panel -->
  <main class="flex items-center justify-center bg-background px-4 py-10 sm:px-8">
    <div class="w-full max-w-sm">
      <div class="mb-8 flex items-center gap-3 lg:hidden">
        <BrandMark class="size-9" />
        <span class="text-lg font-semibold tracking-tight">Office Assistant</span>
      </div>

      <h1 class="text-2xl font-semibold tracking-tight">Вход</h1>
      <p class="mt-1 text-sm text-muted-foreground">Рабочая почта и пароль — те же, что в офисе.</p>

      <Form action="/session" method="post" class="mt-8 space-y-5">
        {#if error}
          <p role="alert" class="rounded-lg border border-destructive/20 bg-destructive/10 px-3 py-2.5 text-sm text-destructive">
            {error}
          </p>
        {/if}

        <div class="space-y-2">
          <label for="email_address" class="text-sm font-medium">Рабочая почта</label>
          <!-- svelte-ignore a11y_autofocus -->
          <input
            id="email_address"
            name="email_address"
            type="email"
            required
            autofocus
            autocomplete="username"
            placeholder="имя.фамилия@office.ru"
            class="h-11 w-full rounded-lg border border-input bg-background px-3.5 text-sm shadow-xs transition-[box-shadow,border-color] outline-none placeholder:text-muted-foreground/60 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/25"
          />
        </div>

        <div class="space-y-2">
          <label for="password" class="text-sm font-medium">Пароль</label>
          <input
            id="password"
            name="password"
            type="password"
            required
            autocomplete="current-password"
            maxlength="72"
            class="h-11 w-full rounded-lg border border-input bg-background px-3.5 text-sm shadow-xs transition-[box-shadow,border-color] outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/25"
          />
        </div>

        <Button type="submit" size="lg" class="h-11 w-full text-[15px]">Войти</Button>
      </Form>

      <p class="mt-8 text-center text-xs text-muted-foreground">
        Нет доступа? Напишите офис-менеджеру — учётные записи заводит он.
      </p>
    </div>
  </main>
</div>
