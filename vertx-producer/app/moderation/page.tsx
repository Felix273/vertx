'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { contentApi } from '@/lib/api'
import { Series, ContentStatus } from '@/types'
import { Card, StatusBadge, Spinner, SectionHeader, EmptyState } from '@/components/ui'
import { Film, ArrowRight, Clock, CheckCircle, XCircle, AlertCircle, FileText } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'

const STATUS_INFO: Record<ContentStatus, { icon: React.ElementType; desc: string; color: string }> = {
  draft:          { icon: FileText,    desc: 'Not yet submitted.',                         color: 'text-muted' },
  pending_review: { icon: Clock,       desc: 'Submitted. Awaiting admin review.',           color: 'text-yellow-400' },
  approved:       { icon: CheckCircle, desc: 'Approved. Being prepared for publication.', color: 'text-green' },
  rejected:       { icon: XCircle,     desc: 'Review feedback available. Edit and resubmit.', color: 'text-accent2' },
  published:      { icon: CheckCircle, desc: 'Live on VERTX. Visible to all viewers.',    color: 'text-accent' },
}

const STEPS: { status: ContentStatus; label: string }[] = [
  { status: 'draft',          label: 'Draft' },
  { status: 'pending_review', label: 'In Review' },
  { status: 'approved',       label: 'Approved' },
  { status: 'published',      label: 'Published' },
]

const STATUS_STEP: Record<ContentStatus, number> = {
  draft: 0, pending_review: 1, approved: 2, rejected: 1, published: 3
}

function ProgressTrack({ status }: { status: ContentStatus }) {
  const current = STATUS_STEP[status]
  const isRejected = status === 'rejected'

  return (
    <div className="flex items-center gap-0 mt-3">
      {STEPS.map((step, i) => {
        const done    = i < current
        const active  = i === current && !isRejected
        const blocked = isRejected && i === 1

        return (
          <div key={step.status} className="flex items-center flex-1 last:flex-none">
            <div className="flex flex-col items-center">
              <div className={`w-5 h-5 border flex items-center justify-center text-[0.5rem] font-mono transition-all ${
                done    ? 'border-accent bg-accent text-black' :
                active  ? 'border-accent3 bg-accent3/20 text-accent3' :
                blocked ? 'border-accent2 bg-accent2/10 text-accent2' :
                          'border-border text-muted'
              }`}>
                {done ? '✓' : i + 1}
              </div>
              <span className={`font-mono text-[0.55rem] tracking-wider mt-1 ${
                done ? 'text-accent' : active ? 'text-accent3' : 'text-muted'
              }`}>
                {step.label}
              </span>
            </div>
            {i < STEPS.length - 1 && (
              <div className={`flex-1 h-px mb-4 mx-1 transition-all ${
                i < current ? 'bg-accent' : 'bg-border'
              }`} />
            )}
          </div>
        )
      })}
    </div>
  )
}

export default function ModerationPage() {
  const [series,  setSeries]  = useState<Series[]>([])
  const [loading, setLoading] = useState(true)
  const [filter,  setFilter]  = useState<ContentStatus | 'all'>('all')

  useEffect(() => {
    contentApi.listSeries()
      .then((r) => setSeries(r.data.results ?? r.data))
      .finally(() => setLoading(false))
  }, [])

  const filtered = filter === 'all'
    ? series
    : series.filter((s) => s.status === filter)

  const counts = {
    pending:   series.filter((s) => s.status === 'pending_review').length,
    published: series.filter((s) => s.status === 'published').length,
    rejected:  series.filter((s) => s.status === 'rejected').length,
  }

  const tabs: { label: string; value: ContentStatus | 'all'; count?: number }[] = [
    { label: 'All',       value: 'all',          count: series.length },
    { label: 'In Review', value: 'pending_review', count: counts.pending },
    { label: 'Published', value: 'published',      count: counts.published },
    { label: 'Rejected',  value: 'rejected',       count: counts.rejected },
    { label: 'Draft',     value: 'draft' },
  ]

  return (
    <div className="animate-fade-in">
      <SectionHeader
        label="Content"
        title="Review Status"
        description="Track the moderation progress of your submitted series."
      />

      {counts.pending > 0 && (
        <div className="mb-6 p-4 border border-yellow-400/20 bg-yellow-400/5 flex items-center gap-3">
          <Clock size={16} className="text-yellow-400 flex-shrink-0" />
          <p className="text-sm text-muted">
            <strong className="text-yellow-400">{counts.pending} series</strong> under review.
            Typically reviewed within 24–48 hours.
          </p>
        </div>
      )}

      {counts.rejected > 0 && (
        <div className="mb-6 p-4 border border-accent2/20 bg-accent2/5 flex items-center gap-3">
          <AlertCircle size={16} className="text-accent2 flex-shrink-0" />
          <p className="text-sm text-muted">
            <strong className="text-accent2">{counts.rejected} series</strong> need your attention.{' '}
            <Link href="/series" className="text-accent3 underline">Edit and resubmit →</Link>
          </p>
        </div>
      )}

      {/* Filter tabs */}
      <div className="flex gap-0 border-b border-border mb-6 overflow-x-auto">
        {tabs.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setFilter(tab.value)}
            className={`px-4 py-2.5 font-mono text-[0.65rem] tracking-widest uppercase border-b-2 transition-colors whitespace-nowrap flex items-center gap-2 ${
              filter === tab.value
                ? 'text-accent border-accent'
                : 'text-muted border-transparent hover:text-text'
            }`}
          >
            {tab.label}
            {tab.count !== undefined && tab.count > 0 && (
              <span className={`text-[0.55rem] px-1.5 py-0.5 ${
                filter === tab.value ? 'bg-accent/20 text-accent' : 'bg-border text-muted'
              }`}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner size={28} /></div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<Film />}
          title="No series here"
          description="Nothing in this category yet."
        />
      ) : (
        <div className="space-y-4">
          {filtered.map((s) => {
            const info = STATUS_INFO[s.status]
            const Icon = info.icon

            return (
              <Card key={s.id} className="p-5">
                <div className="flex items-start gap-4">
                  <div className="w-14 h-14 bg-surface border border-border flex-shrink-0 flex items-center justify-center text-muted">
                    {s.thumbnail_url
                      ? <img src={s.thumbnail_url} alt="" className="w-full h-full object-cover" />
                      : <Film size={18} />
                    }
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-1 flex-wrap">
                      <p className="font-syne font-bold text-base">{s.title}</p>
                      <StatusBadge status={s.status} />
                    </div>

                    <div className="flex items-center gap-2 mb-1">
                      <Icon size={12} className={info.color} />
                      <p className="text-muted text-xs">{info.desc}</p>
                    </div>

                    <p className="font-mono text-[0.6rem] text-muted">
                      Updated {formatDistanceToNow(new Date(s.updated_at), { addSuffix: true })} · {s.episode_count} episodes
                    </p>

                    <ProgressTrack status={s.status} />
                  </div>

                  <Link href={`/series/${s.id}`} className="text-muted hover:text-accent3 transition-colors p-1 flex-shrink-0 mt-1">
                    <ArrowRight size={16} />
                  </Link>
                </div>
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}
