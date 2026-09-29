'use client'

import { useEffect, useState } from 'react'
import { adminApi } from '@/lib/admin-api'
import { Card, SectionHeader, Spinner } from '@/components/ui'
import {
  Film, Users, CreditCard, CheckCircle,
  Clock, XCircle, TrendingUp, Eye, RefreshCw,
} from 'lucide-react'
import toast from 'react-hot-toast'

interface Stats {
  total_series:    number
  published:       number
  pending_review:  number
  rejected:        number
  draft:           number
  total_users:     number
  producers:       number
  viewers:         number
  total_revenue:   string
  active_subs:     number
}

export default function AdminStatsPage() {
  const [stats,   setStats]   = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error,   setError]   = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    adminApi.getStats()
      .then((r) => setStats(r.data))
      .catch(() => { setError(true); toast.error('Could not refresh platform stats.') })
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  if (loading) return <div className="flex justify-center py-20"><Spinner size={28} /></div>

  // Keep the admin shell usable if the API is temporarily unavailable.
  if (error || !stats) return <StatsUnavailable />

  const statCards = [
    { label: 'Total Series',   value: stats.total_series,   icon: Film,        color: 'text-text' },
    { label: 'Published',      value: stats.published,      icon: CheckCircle, color: 'text-accent' },
    { label: 'Pending Review', value: stats.pending_review, icon: Clock,       color: 'text-yellow-400' },
    { label: 'Total Users',    value: stats.total_users,    icon: Users,       color: 'text-accent3' },
    { label: 'Producers',      value: stats.producers,      icon: Eye,         color: 'text-violet-400' },
    { label: 'Viewers',        value: stats.viewers,        icon: Eye,         color: 'text-muted' },
    { label: 'Active Subs',    value: stats.active_subs,    icon: TrendingUp,  color: 'text-green' },
    { label: 'Total Revenue',  value: `KES ${stats.total_revenue}`, icon: CreditCard, color: 'text-accent' },
  ]

  return (
    <div className="animate-fade-in">
      <div className="mb-8 flex flex-col justify-between gap-4 md:flex-row md:items-end">
        <SectionHeader label="Admin / Overview" title="Platform Stats" description="A calm, real-time view of the VERTX network." />
        <button onClick={load} className="inline-flex items-center gap-2 self-start rounded-lg border border-border px-3 py-2 font-mono text-[0.62rem] uppercase tracking-widest text-muted transition hover:border-accent hover:text-accent md:self-auto">
          <RefreshCw size={13} className={loading ? 'animate-spin' : ''} /> Refresh
        </button>
      </div>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        {statCards.map(({ label, value, icon: Icon, color }) => (
          <Card key={label} className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">{label}</p>
                <p className={`font-syne font-black text-2xl ${color}`}>{value}</p>
              </div>
              <Icon size={18} className={`${color} opacity-40 mt-1`} />
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

// Shown if /admin/stats/ endpoint not yet built
function StatsUnavailable() {
  return (
    <div className="animate-fade-in">
      <SectionHeader label="Admin" title="Platform Stats" />
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {['Total Series', 'Published', 'Pending Review', 'Total Users',
          'Producers', 'Viewers', 'Active Subs', 'Revenue'].map((label) => (
          <Card key={label} className="p-4">
            <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">{label}</p>
            <p className="font-syne font-black text-2xl text-border">—</p>
          </Card>
        ))}
      </div>
      <p className="text-muted text-xs mt-6 font-mono">
        The stats service is temporarily unavailable. Try refreshing in a moment.
      </p>
    </div>
  )
}
