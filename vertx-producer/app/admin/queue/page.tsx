'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { CheckCircle, XCircle, Film, ArrowRight, Clock } from 'lucide-react'
import { adminApi } from '@/lib/admin-api'
import { Series } from '@/types'
import {
  Card, StatusBadge, Spinner, SectionHeader,
  EmptyState, Button, Modal
} from '@/components/ui'
import { formatDistanceToNow } from 'date-fns'

export default function AdminQueuePage() {
  const [queue,    setQueue]    = useState<Series[]>([])
  const [all,      setAll]      = useState<Series[]>([])
  const [loading,  setLoading]  = useState(true)
  const [tab,      setTab]      = useState<'pending' | 'all'>('pending')
  const [rejectTarget, setRejectTarget] = useState<Series | null>(null)
  const [rejectNote,   setRejectNote]   = useState('')
  const [acting,       setActing]       = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    Promise.all([
      adminApi.getQueue(),
      adminApi.getAllSeries(),
    ]).then(([q, a]) => {
      setQueue(q.data.results ?? q.data)
      setAll(a.data.results ?? a.data)
    }).catch(() => toast.error('Failed to load queue.'))
    .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleApprove = async (s: Series) => {
    setActing(s.id)
    try {
      await adminApi.approveSeries(s.id)
      toast.success(`"${s.title}" published.`)
      load()
    } catch { toast.error('Approval failed.') }
    finally { setActing(null) }
  }

  const handleReject = async () => {
    if (!rejectTarget || !rejectNote.trim()) return
    setActing(rejectTarget.id)
    try {
      await adminApi.rejectSeries(rejectTarget.id, rejectNote)
      toast.success(`"${rejectTarget.title}" rejected.`)
      setRejectTarget(null)
      setRejectNote('')
      load()
    } catch { toast.error('Rejection failed.') }
    finally { setActing(null) }
  }

  const display = tab === 'pending' ? queue : all

  return (
    <div className="animate-fade-in">
      <SectionHeader
        label="Admin"
        title="Review Queue"
        description="Approve or reject producer submissions."
      />

      {queue.length > 0 && (
        <div className="mb-6 p-4 border border-yellow-400/20 bg-yellow-400/5 flex items-center gap-3">
          <Clock size={16} className="text-yellow-400 flex-shrink-0" />
          <p className="text-sm text-muted">
            <strong className="text-yellow-400">{queue.length} series</strong> waiting for review.
          </p>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-0 border-b border-border mb-6">
        {[
          { key: 'pending', label: 'Pending Review', count: queue.length },
          { key: 'all',     label: 'All Series',     count: all.length },
        ].map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key as 'pending' | 'all')}
            className={`px-4 py-2.5 font-mono text-[0.65rem] tracking-widest uppercase border-b-2 transition-colors flex items-center gap-2 ${
              tab === t.key
                ? 'text-accent2 border-accent2'
                : 'text-muted border-transparent hover:text-text'
            }`}
          >
            {t.label}
            {t.count > 0 && (
              <span className={`text-[0.55rem] px-1.5 py-0.5 ${
                tab === t.key ? 'bg-accent2/20 text-accent2' : 'bg-border text-muted'
              }`}>
                {t.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner size={28} /></div>
      ) : display.length === 0 ? (
        <EmptyState icon={<CheckCircle />} title="Queue is empty" description="No series waiting for review." />
      ) : (
        <div className="space-y-3">
          {display.map((s) => (
            <Card key={s.id} className="p-4">
              <div className="flex items-start gap-4">

                {/* Thumbnail */}
                <div className="w-16 h-16 bg-surface border border-border flex-shrink-0 flex items-center justify-center text-muted">
                  {s.thumbnail_url
                    ? <img src={s.thumbnail_url} alt="" className="w-full h-full object-cover" />
                    : <Film size={20} />
                  }
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-3 mb-1 flex-wrap">
                    <p className="font-syne font-bold text-base">{s.title}</p>
                    <StatusBadge status={s.status} />
                  </div>
                  <p className="text-muted text-xs line-clamp-1 mb-1">{s.description}</p>
                  <div className="flex gap-3">
                    <span className="font-mono text-[0.6rem] text-muted uppercase">{s.genre}</span>
                    <span className="font-mono text-[0.6rem] text-muted">{s.episode_count} episodes</span>
                    <span className="font-mono text-[0.6rem] text-muted">
                      {formatDistanceToNow(new Date(s.updated_at), { addSuffix: true })}
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 flex-shrink-0">
                  {s.status === 'pending_review' && (
                    <>
                      <Button
                        size="sm"
                        loading={acting === s.id}
                        icon={<CheckCircle size={12} />}
                        onClick={() => handleApprove(s)}
                      >
                        Approve
                      </Button>
                      <Button
                        size="sm"
                        variant="danger"
                        icon={<XCircle size={12} />}
                        onClick={() => { setRejectTarget(s); setRejectNote('') }}
                      >
                        Reject
                      </Button>
                    </>
                  )}
                  <Link href={`/series/${s.id}`} className="p-2 text-muted hover:text-accent3 transition-colors">
                    <ArrowRight size={14} />
                  </Link>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Reject modal */}
      <Modal open={!!rejectTarget} onClose={() => setRejectTarget(null)} title="Reject Series">
        <p className="text-muted text-sm mb-4">
          Rejecting <strong className="text-text">&ldquo;{rejectTarget?.title}&rdquo;</strong>.
          The producer will see your note.
        </p>
        <textarea
          value={rejectNote}
          onChange={(e) => setRejectNote(e.target.value)}
          placeholder="Reason for rejection (required)..."
          rows={4}
          className="w-full bg-surface border border-border px-3 py-2.5 text-sm text-text placeholder:text-muted/50 resize-none focus:outline-none focus:border-accent3 mb-4"
        />
        <div className="flex gap-3 justify-end">
          <Button variant="secondary" onClick={() => setRejectTarget(null)}>Cancel</Button>
          <Button
            variant="danger"
            loading={!!acting}
            disabled={!rejectNote.trim()}
            onClick={handleReject}
          >
            Reject Series
          </Button>
        </div>
      </Modal>
    </div>
  )
}
