export type UserRole = 'viewer' | 'producer' | 'admin'

export interface User {
  id:         string
  email:      string
  full_name:  string
  role:       UserRole
  created_at: string
  is_active?: boolean
}

export interface ProducerProfile {
  id:          string
  user:        User
  studio_name: string
  bio:         string
  avatar_url:  string
  website:     string
  verified:    boolean
  created_at:  string
}

export type ContentStatus =
  | 'draft'
  | 'pending_review'
  | 'approved'
  | 'rejected'
  | 'published'

export type Genre =
  | 'drama' | 'thriller' | 'romance' | 'comedy'
  | 'action' | 'horror'  | 'documentary' | 'scifi' | 'other'

export interface Episode {
  id:             string
  episode_number: number
  title:          string
  description:    string
  video_url:      string
  video_id:       string
  duration_secs:  number
  duration_display: string
  thumbnail_url:  string
  created_at:     string
}

export interface Series {
  id:            string
  title:         string
  description:   string
  genre:         Genre
  thumbnail_url: string
  trailer_url:   string
  price:         string
  is_free:       boolean
  status:        ContentStatus
  episode_count: number
  episodes:      Episode[]
  created_at:    string
  updated_at:    string
}

export interface Payment {
  id:         string
  provider:   string
  amount:     string
  currency:   string
  status:      'pending' | 'success' | 'failed' | 'refunded'
  payment_type?: string
  series_title?: string
  created_at: string
}

export const STATUS_LABELS: Record<ContentStatus, string> = {
  draft:          'Draft',
  pending_review: 'In Review',
  approved:       'Approved',
  rejected:       'Rejected',
  published:      'Published',
}

export const STATUS_COLORS: Record<ContentStatus, string> = {
  draft:          'text-muted border-border',
  pending_review: 'text-yellow-400 border-yellow-400/30 bg-yellow-400/8',
  approved:       'text-green border-green/30 bg-green/8',
  rejected:       'text-accent2 border-accent2/30 bg-accent2/8',
  published:      'text-accent border-accent/30 bg-accent/8',
}

export const GENRES: { value: Genre; label: string }[] = [
  { value: 'drama',       label: 'Drama' },
  { value: 'thriller',    label: 'Thriller' },
  { value: 'romance',     label: 'Romance' },
  { value: 'comedy',      label: 'Comedy' },
  { value: 'action',      label: 'Action' },
  { value: 'horror',      label: 'Horror' },
  { value: 'documentary', label: 'Documentary' },
  { value: 'scifi',       label: 'Sci-Fi' },
  { value: 'other',       label: 'Other' },
]
