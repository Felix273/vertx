'use client'

import { useEffect, useState } from 'react'
import { adminApi } from '@/lib/admin-api'
import { Card, SectionHeader, Spinner } from '@/components/ui'
import {
  Film, Users, CreditCard, CheckCircle,
  Clock, XCircle, TrendingUp, Eye,
} from 'lucide-react'

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

  useEffect(() => {
    adminApi.getStats()
      .then((r) => setStats(r.data))
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="flex justify-center py-20"><Spinner size={28} /></div>

  // If stats endpoint doesn't exist yet, show a useful fallback
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
      <SectionHeader label="Admin" title="Platform Stats" description="Real-time overview of VERTX." />
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
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
        Add <code className="text-accent3">/admin/stats/</code> endpoint to Django to enable live stats.
      </p>
    </div>
  )
}
