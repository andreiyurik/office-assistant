export type FlashData = {
  notice?: string
  alert?: string
}

export type CurrentUser = {
  id: number
  name: string
  team_name: string
  zone_name: string
}

export type PendingCheckIn = {
  id: number
  room_name: string
  starts_at: string
  releases_at: string
}

export type SharedProps = {
  current_user: CurrentUser | null
  pending_check_in: PendingCheckIn | null
}
