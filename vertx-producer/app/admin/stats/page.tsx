'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'
import {
  ArrowUpRight, BarChart3, CheckCircle, Clock, CreditCard,
  Film, RefreshCw, ShieldCheck, Sparkles, Users,
} from 'lucide-react'
import { adminApi } from '@/lib/admin-api'
import { Card, Spinner } from '@/components/ui'

interface Stats {
  total_series: number
  published: number
  pending_review: number
  rejected: number
  draft: number
  total_users: number
  producers: number
  viewers: number
  total_revenue: string
  active_subs: number
}

export default function AdminStatsPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  const load = () => {
    setLoading(true)
    setError(false)
    adminApi.getStats()
      .then((response) => setStats(response.data))
      .catch(() => {
        setError(true)
        toast.error('Could not refresh platform stats.')
      })
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  if (loading && !stats) {
    return <div className="flex min-h-[60vh] items-center justify-center"><Spinner size={30} /></div>
  }

  if (error || !stats) {
    return (
      <div className="rounded-3xl border border-accent2/20 bg-accent2/5 p-8">
        <p className="admin-kicker text-accent2">System notice</p>
        <h1 className="mt-3 font-syne text-3xl font-black">The command center is offline.</h1>
        <p className="mt-2 max-w-lg text-sm leading-6 text-muted">Stats could not be loaded. The rest of your workspace remains available while we reconnect.</p>
        <button onClick={load} className="mt-6 inline-flex items-center gap-2 rounded-xl bg-accent px-4 py-3 font-mono text-xs font-bold uppercase tracking-widest text-black"><RefreshCw size={14} /> Retry connection</button>
      </div>
    )
  }

  const cards = [
    { label: 'Published stories', value: stats.published, meta: `${stats.total_series} total in library`, icon: Film, tone: 'accent' },
    { label: 'Waiting for review', value: stats.pending_review, meta: 'Needs an editorial decision', icon: Clock, tone: 'amber' },
    { label: 'Active community', value: stats.total_users, meta: `${stats.producers} producers · ${stats.viewers} viewers`, icon: Users, tone: 'violet' },
    { label: 'Gross revenue', value: `KES ${stats.total_revenue}`, meta: `${stats.active_subs} active subscriptions`, icon: CreditCard, tone: 'green' },
  ]

  const tone: Record<string, string> = {
    accent: 'text-accent border-accent/20 bg-accent/5',
    amber: 'text-yellow-300 border-yellow-300/20 bg-yellow-300/5',
    violet: 'text-accent3 border-accent3/20 bg-accent3/5',
    green: 'text-green border-green/20 bg-green/5',
  }

  return (
    <div className="animate-fade-in space-y-6">
      <section className="relative overflow-hidden rounded-[2rem] border border-accent/20 bg-[#111326] p-6 shadow-[0_24px_80px_rgba(0,0,0,0.28)] md:p-10">
        <div className="pointer-events-none absolute -right-24 -top-32 h-80 w-80 rounded-full bg-accent/20 blur-3xl" />
        <div className="pointer-events-none absolute bottom-[-8rem] left-1/3 h-64 w-64 rounded-full bg-accent3/10 blur-3xl" />
        <div className="relative flex flex-col justify-between gap-10 md:flex-row md:items-end">
          <div className="max-w-2xl">
            <div className="mb-5 flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-2 rounded-full border border-green/25 bg-green/10 px-3 py-1.5 font-mono text-[0.6rem] uppercase tracking-[0.18em] text-green"><span className="h-1.5 w-1.5 rounded-full bg-green shadow-[0_0_10px_#22f2a6]" /> Live platform</span>
              <span className="rounded-full border border-white/10 px-3 py-1.5 font-mono text-[0.6rem] uppercase tracking-[0.18em] text-muted">Nairobi / EAT</span>
            </div>
            <p className="admin-kicker text-accent">VERTX / command center</p>
            <h1 className="mt-3 max-w-xl font-syne text-4xl font-black leading-[0.95] tracking-tight md:text-6xl">Stories move when you do.</h1>
            <p className="mt-5 max-w-xl text-sm leading-7 text-muted md:text-base">A live pulse of the catalogue, the creators behind it, and the audience discovering the next local classic.</p>
          </div>
          <div className="relative min-w-[190px] rounded-2xl border border-white/10 bg-black/20 p-5 backdrop-blur-md">
            <div className="flex items-center justify-between"><span className="admin-kicker">Network health</span><ShieldCheck size={17} className="text-green" /></div>
            <div className="mt-5 flex items-end gap-2"><span className="font-syne text-5xl font-black text-text">98</span><span className="mb-2 font-mono text-xs text-green">.4%</span></div>
            <div className="mt-4 h-1.5 overflow-hidden rounded-full bg-white/10"><div className="h-full w-[98%] rounded-full bg-gradient-to-r from-green to-accent" /></div>
            <p className="mt-3 font-mono text-[0.58rem] uppercase tracking-widest text-muted">All core services operational</p>
          </div>
        </div>
        <div className="relative mt-10 grid grid-cols-3 gap-3 border-t border-white/10 pt-5 md:max-w-xl">
          <div><p className="admin-kicker">Catalog</p><p className="mt-1 font-syne text-xl font-black">{stats.total_series}</p></div>
          <div><p className="admin-kicker">Creators</p><p className="mt-1 font-syne text-xl font-black">{stats.producers}</p></div>
          <div><p className="admin-kicker">Subscribers</p><p className="mt-1 font-syne text-xl font-black">{stats.active_subs}</p></div>
        </div>
      </section>

      <div className="flex items-center justify-between gap-4">
        <div><p className="admin-kicker text-accent">Today at a glance</p><h2 className="mt-1 font-syne text-2xl font-bold">The numbers behind the stories</h2></div>
        <button onClick={load} className="inline-flex items-center gap-2 rounded-xl border border-border px-3 py-2 font-mono text-[0.6rem] uppercase tracking-widest text-muted transition hover:border-accent hover:text-accent"><RefreshCw size={13} className={loading ? 'animate-spin' : ''} /> Refresh</button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map(({ label, value, meta, icon: Icon, tone: cardTone }) => (
          <Card key={label} className={`border p-5 ${tone[cardTone]}`}>
            <div className="flex items-start justify-between"><p className="admin-kicker">{label}</p><Icon size={18} /></div>
            <p className="mt-5 break-words font-syne text-3xl font-black text-text">{value}</p>
            <p className="mt-2 text-xs text-muted">{meta}</p>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-[1.25fr_0.75fr]">
        <Card className="overflow-hidden p-0">
          <div className="flex items-start justify-between border-b border-border p-5"><div><p className="admin-kicker text-accent3">Editorial pipeline</p><h2 className="mt-1 font-syne text-xl font-bold">Keep the front page fresh</h2></div><BarChart3 size={18} className="text-accent3" /></div>
          <div className="space-y-5 p-5">
            {[
              ['Published', stats.published, stats.total_series, 'bg-accent'],
              ['Pending review', stats.pending_review, stats.total_series, 'bg-yellow-300'],
              ['Drafts', stats.draft, stats.total_series, 'bg-accent3'],
              ['Rejected', stats.rejected, stats.total_series, 'bg-accent2'],
            ].map(([label, value, total, bar]) => {
              const percent = Number(total) ? Math.min(100, (Number(value) / Number(total)) * 100) : 0
              return <div key={String(label)}><div className="mb-2 flex justify-between text-xs"><span className="text-muted">{label}</span><span className="font-mono text-text">{value}</span></div><div className="h-2 rounded-full bg-white/5"><div className={`h-full rounded-full ${bar}`} style={{ width: `${percent}%` }} /></div></div>
            })}
          </div>
        </Card>
        <Card className="relative overflow-hidden bg-gradient-to-br from-accent3/15 via-card to-card p-6">
          <Sparkles size={22} className="text-accent3" />
          <p className="admin-kicker mt-8 text-accent3">Next best action</p>
          <h2 className="mt-2 font-syne text-2xl font-black">{stats.pending_review ? `Review ${stats.pending_review} waiting ${stats.pending_review === 1 ? 'story' : 'stories'}.` : 'The queue is clear.'}</h2>
          <p className="mt-3 text-sm leading-6 text-muted">Make the next editorial decision that helps a creator reach an audience.</p>
          <Link href="/admin/queue" className="mt-7 inline-flex items-center gap-2 rounded-xl bg-accent3 px-4 py-3 text-xs font-bold uppercase tracking-widest text-black transition hover:translate-y-[-2px]">Open review queue <ArrowUpRight size={14} /></Link>
        </Card>
      </div>
    </div>
  )
}
