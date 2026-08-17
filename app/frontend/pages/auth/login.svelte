<script lang="ts">
  import { Form } from '@inertiajs/svelte'
  import { Button, InlineNotification, PasswordInput, TextInput } from 'carbon-components-svelte'
  import ArrowRight from 'carbon-icons-svelte/lib/ArrowRight.svelte'
  import Calendar from 'carbon-icons-svelte/lib/Calendar.svelte'
  import Grid from 'carbon-icons-svelte/lib/Grid.svelte'
  import UserMultiple from 'carbon-icons-svelte/lib/UserMultiple.svelte'
  import { firstError } from '@/lib/format'

  let { errors = {} }: { errors?: Record<string, string[] | string> } = $props()

  const error = $derived(firstError(errors))

  // What the product does, in the order a person meets it. Shown on the wide
  // layout only; the form is the whole story on a phone.
  const points = [
    { icon: UserMultiple, title: 'Кто сегодня в офисе', text: 'Список на неделю вперёд, по командам.' },
    { icon: Grid, title: 'Место рядом с командой', text: 'Карта этажа, бронь в один клик, своё место каждую неделю.' },
    { icon: Calendar, title: 'Переговорная без накладок', text: 'Слоты по полчаса; забытая бронь освобождается сама.' },
  ]
</script>

<svelte:head>
  <title>Вход — Office Assistant</title>
</svelte:head>

<div class="login">
  <!-- Gray 100 under a light theme is what Carbon's inverse surface tokens are
       for, so the panel is a token pair rather than a colour picked by hand. -->
  <aside class="login__brand">
    <div class="bx--type-productive-heading-03">Office <strong>Assistant</strong></div>

    <div>
      <h2 class="bx--type-expressive-heading-04">
        Гибридный офис, в котором понятно, где и с кем ты окажешься.
      </h2>
      <ul class="login__points">
        {#each points as point (point.title)}
          <li>
            <point.icon size={24} aria-hidden="true" />
            <span>
              <span class="bx--type-productive-heading-01">{point.title}</span>
              <span class="bx--type-body-long-01">{point.text}</span>
            </span>
          </li>
        {/each}
      </ul>
    </div>

    <p class="bx--type-caption-01">Внутренний сервис. Вход по рабочей почте.</p>
  </aside>

  <main class="login__panel">
    <div class="login__form">
      <div class="login__wordmark bx--type-productive-heading-03">Office <strong>Assistant</strong></div>

      <h1 class="bx--type-productive-heading-04">Вход</h1>
      <p class="login__lede bx--type-body-long-01">Рабочая почта и пароль — те же, что в офисе.</p>

      {#if error}
        <InlineNotification kind="error" lowContrast hideCloseButton subtitle={error} />
      {/if}

      <Form action="/session" method="post" class="bx--form">
        <TextInput
          id="email_address"
          name="email_address"
          type="email"
          labelText="Рабочая почта"
          placeholder="имя.фамилия@office.ru"
          autocomplete="username"
          required
        />

        <PasswordInput
          id="password"
          name="password"
          labelText="Пароль"
          autocomplete="current-password"
          maxlength={72}
          hidePasswordLabel="Скрыть пароль"
          showPasswordLabel="Показать пароль"
          tooltipAlignment="end"
          required
        />

        <Button type="submit" icon={ArrowRight}>Войти</Button>
      </Form>

      <p class="login__foot bx--type-caption-01">
        Нет доступа? Напишите офис-менеджеру — учётные записи заводит он.
      </p>
    </div>
  </main>
</div>

<style>
  .login {
    min-height: 100vh;
    display: grid;
    grid-template-columns: 1fr;
  }

  .login__brand {
    display: none;
    flex-direction: column;
    justify-content: space-between;
    gap: var(--cds-spacing-09);
    padding: var(--cds-spacing-09);
    background-color: var(--cds-ui-05);
    color: var(--cds-text-04);
  }

  .login__brand h2 {
    max-width: 24ch;
  }

  .login__brand > p {
    color: var(--cds-text-03);
  }

  .login__points {
    margin-block-start: var(--cds-spacing-08);
    display: grid;
    gap: var(--cds-spacing-06);
  }

  .login__points li {
    display: flex;
    gap: var(--cds-spacing-05);
  }

  .login__points li > span {
    display: grid;
    gap: var(--cds-spacing-02);
  }

  .login__points li :global(svg) {
    flex-shrink: 0;
    margin-block-start: var(--cds-spacing-02);
    fill: currentColor;
  }

  .login__points span span:last-child {
    color: var(--cds-text-03);
  }

  .login__panel {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--cds-spacing-07) var(--cds-spacing-05);
    /* Carbon's layer model: the page sits on ui-background and fields come
       forward on field-01. On ui-01 the white field would have nothing but
       its underline to be seen by. */
    background-color: var(--cds-ui-background);
  }

  .login__form {
    width: 100%;
    max-width: 24rem;
  }

  .login__wordmark {
    margin-block-end: var(--cds-spacing-07);
  }

  .login__lede {
    color: var(--cds-text-02);
    margin-block: var(--cds-spacing-02) var(--cds-spacing-07);
  }

  .login__foot {
    color: var(--cds-text-02);
    margin-block-start: var(--cds-spacing-07);
  }

  /* Carbon's form class only sets a max width; the stack rhythm and the
     submit button spacing are the page's own. */
  .login__form :global(.bx--form) {
    display: grid;
    gap: var(--cds-spacing-06);
  }

  /* The submit spans the fields above it, and the label and the arrow sit
     together in the middle. Carbon pins a button icon to the right edge and
     pushes the label left, which reads well on a button sized to its text and
     strands the two at opposite ends of a full-width bar.
     Direct child only: the password field's show/hide toggle is a .bx--btn too,
     and stretching that one pushes the eye into the middle of the field. */
  .login__form :global(.bx--form > .bx--btn) {
    width: 100%;
    max-width: none;
    justify-content: center;
    gap: var(--cds-spacing-03);
    padding-inline: var(--cds-spacing-05);
  }

  .login__form :global(.bx--form > .bx--btn .bx--btn__icon) {
    position: static;
    margin: 0;
  }

  .login__form :global(.bx--form-item) {
    width: 100%;
  }

  .login__form :global(.bx--inline-notification) {
    max-width: 100%;
    margin-block: 0 var(--cds-spacing-06);
  }

  /* The large breakpoint is where Carbon expects two columns to fit. */
  @media (min-width: 66rem) {
    .login {
      grid-template-columns: 1.1fr 1fr;
    }

    .login__brand {
      display: flex;
    }

    .login__wordmark {
      display: none;
    }
  }
</style>
