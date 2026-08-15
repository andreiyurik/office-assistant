<script lang="ts">
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import type { CurrentUser } from '@/types'

  let { current_user }: { current_user: CurrentUser } = $props()
</script>

<svelte:head>
  <title>Карта мест — Office Assistant</title>
</svelte:head>

<AppLayout {current_user}>
  <h1 class="text-xl font-semibold tracking-tight">Карта мест</h1>
</AppLayout>
