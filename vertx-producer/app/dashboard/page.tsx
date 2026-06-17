'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Film, Clock, CheckCircle, XCircle, Upload, ArrowRight, TrendingUp } from 'lucide-react'
import { useAuth } from '@/lib/auth-context'
import { contentApi } from '@/lib/api'
import { Series, ContentStatus } from '@/types'
import { Card, StatusBadge, Spinner, Button } from '@/components/ui'
import { formatDistanceToNow } from 'date-fns'

export default function DashboardPage() {
  const { user, profile } = useAuth()
  const router = useRouter()
  const [series,  setSeries]  = useState<Series[]>([])
  const [loading, setLoading] = useState(true)

  // Admins don't belong on the producer dashboard — send to admin stats
  useEffect(() => {
    if (user && user.role === 'admin') {
      router.replace('/admin/stats')
      return
    }
    if (user) {
      contentApi.listSeries()
        .then((r) => setSeries(r.data.results ?? r.data))
        .catch(() => {})
        .finally(() => setLoading(false))
    }
  }, [user, router])

  const counts = {
    total:    series.length,
    published: series.filter((s) => s.status === 'published').length,
    pending:  series.filter((s) => s.status === 'pending_review').length,
    rejected: series.filter((s) => s.status === 'rejected').length,
    draft:    series.filter((s) => s.status === 'draft').length,
  }

  const recent = [...series].sort(
    (a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
  ).slice(0, 5)

  return (
    <div className="animate-fade-in">

      {/* Welcome */}
      <div className="mb-8">
        <p className="font-mono text-[0.65rem] text-accent tracking-widest uppercase flex items-center gap-2 mb-2">
          <span className="w-6 h-px bg-accent" />
          Overview
        </p>
        <h1 className="font-syne font-black text-3xl tracking-tight">
          {profile ? profile.studio_name : user?.full_name || 'Dashboard'}
        </h1>
        <p className="text-muted text-sm mt-1">Manage your content on VERTX.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
        {[
          { label: 'Total Series',  value: counts.total,    icon: Film,         color: 'text-text' },
          { label: 'Published',     value: counts.published, icon: CheckCircle,  color: 'text-accent' },
          { label: 'In Review',     value: counts.pending,  icon: Clock,        color: 'text-yellow-400' },
          { label: 'Rejected',      value: counts.rejected, icon: XCircle,      color: 'text-accent2' },
        ].map(({ label, value, icon: Icon, color }) => (
          <Card key={label} className="p-4">
            <div className="flex items-start justify-between">
              <div>
                <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">{label}</p>
                <p className={`font-syne font-black text-3xl ${color}`}>
                  {loading ? '—' : value}
                </p>
              </div>
              <Icon size={18} className={`${color} opacity-40 mt-1`} />
            </div>
          </Card>
        ))}
      </div>

      <div className="grid md:grid-cols-3 gap-6">

        {/* Recent series */}
        <div className="md:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-syne font-bold text-base">Recent Series</h2>
            <Link href="/series" className="font-mono text-[0.65rem] text-accent3 hover:text-accent3/80 flex items-center gap-1 tracking-widest uppercase">
              All <ArrowRight size={12} />
            </Link>
          </div>

          {loading ? (
            <div className="flex justify-center py-12"><Spinner /></div>
          ) : recent.length === 0 ? (
            <Card className="p-8 text-center">
              <Film size={32} className="text-muted/40 mx-auto mb-3" />
              <p className="font-syne font-bold text-sm mb-1">No series yet</p>
              <p className="text-muted text-xs mb-4">Start by creating your first series.</p>
              <Link href="/series/new">
                <Button size="sm" icon={<Upload size={12} />}>Create Series</Button>
              </Link>
            </Card>
          ) : (
            <div className="space-y-2">
              {recent.map((s) => (
                <Card key={s.id} className="flex items-center gap-4 p-4 hover:border-border/80 transition-colors">
                  <div className="w-12 h-12 bg-surface border border-border flex items-center justify-center flex-shrink-0 text-muted">
                    {s.thumbnail_url
                      ? <img src={s.thumbnail_url} alt="" className="w-full h-full object-cover" />
                      : <Film size={18} />
                    }
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-syne font-bold text-sm truncate">{s.title}</p>
                    <p className="font-mono text-[0.6rem] text-muted mt-0.5">
                      {s.episode_count} ep · updated {formatDistanceToNow(new Date(s.updated_at), { addSuffix: true })}
                    </p>
                  </div>
                  <div className="flex items-center gap-3 flex-shrink-0">
                    <StatusBadge status={s.status} />
                    <Link href={`/series/${s.id}`} className="text-muted hover:text-text">
                      <ArrowRight size={14} />
                    </Link>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Quick actions */}
        <div>
          <h2 className="font-syne font-bold text-base mb-4">Quick Actions</h2>
          <div className="space-y-2">
            <Link href="/series/new" className="block">
              <Card className="p-4 hover:border-accent/40 transition-colors group cursor-pointer">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 bg-accent/10 border border-accent/20 flex items-center justify-center text-accent group-hover:bg-accent/15 transition-colors">
                    <Upload size={16} />
                  </div>
                  <div>
                    <p className="font-syne font-bold text-sm">New Series</p>
                    <p className="text-muted text-xs">Create and upload content</p>
                  </div>
                </div>
              </Card>
            </Link>

            <Link href="/moderation" className="block">
              <Card className="p-4 hover:border-accent3/40 transition-colors group cursor-pointer">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 bg-accent3/10 border border-accent3/20 flex items-center justify-center text-accent3 group-hover:bg-accent3/15 transition-colors">
                    <TrendingUp size={16} />
                  </div>
                  <div>
                    <p className="font-syne font-bold text-sm">Review Status</p>
                    <p className="text-muted text-xs">Track moderation progress</p>
                  </div>
                </div>
              </Card>
            </Link>
          </div>

          {/* Counts by status */}
          {!loading && series.length > 0 && (
            <Card className="mt-4 p-4">
              <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-3">By Status</p>
              {(['published', 'pending_review', 'draft', 'rejected'] as ContentStatus[]).map((st) => {
                const count = series.filter((s) => s.status === st).length
                const pct   = counts.total > 0 ? (count / counts.total) * 100 : 0
                return (
                  <div key={st} className="mb-3 last:mb-0">
                    <div className="flex justify-between font-mono text-[0.6rem] mb-1">
                      <span className="text-muted uppercase tracking-widest">{st.replace('_', ' ')}</span>
                      <span className="text-text">{count}</span>
                    </div>
                    <div className="h-1 bg-border">
                      <div
                        className="h-full bg-accent3 transition-all duration-500"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                )
              })}
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
