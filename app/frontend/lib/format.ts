// Formatting shared by the pages. Everything here was written in two or three
// components before it moved into one place.

// A date prop is a plain "2026-08-16": parsed as local midnight so the day
// never shifts by one.
export function asDate(iso: string): Date {
  return new Date(`${iso}T00:00:00`)
}

export function time(iso: string): string {
  return new Date(iso).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
}

export function initials(name: string): string {
  return name
    .split(' ')
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
}

// Inertia sends errors as a map of field to message (or messages). A page that
// shows one toast only needs the first of them.
export function firstError(errors: Record<string, string[] | string>): string | null {
  const value = Object.values(errors).find(Boolean)
  if (!value) return null

  return Array.isArray(value) ? (value[0] ?? null) : value
}
