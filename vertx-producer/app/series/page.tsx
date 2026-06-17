'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { Film, Plus, Trash2, ArrowRight, Send } from 'lucide-react'
import { contentApi } from '@/lib/api'
import { Series } from '@/types'
import {
  Button, Card, StatusBadge, Spinner, EmptyState, SectionHeader, Modal
} from '@/components/ui'
import { formatDistanceToNow } from 'date-fns'

export default function SeriesPage() {
  const [series,       setSeries]       = useState<Series[]>([])
  const [loading,      setLoading]      = useState(true)
  const [deleteTarget, setDeleteTarget] = useState<Series | null>(null)
  const [deleting,     setDeleting]     = useState(false)
  const [submitting,   setSubmitting]   = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    contentApi.listSeries()
      .then((r) => setSeries(r.data.results ?? r.data))
      .catch(() => toast.error('Failed to load series.'))
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await contentApi.deleteSeries(deleteTarget.id)
      toast.success(`"${deleteTarget.title}" deleted.`)
      setSeries((prev) => prev.filter((s) => s.id !== deleteTarget.id))
      setDeleteTarget(null)
    } catch {
      toast.error('Could not delete series.')
    } finally {
      setDeleting(false)
    }
  }

  const handleSubmit = async (s: Series) => {
    setSubmitting(s.id)
    try {
      await contentApi.submitSeries(s.id)
      toast.success(`"${s.title}" submitted for review.`)
      load()
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      toast.error(msg || 'Submission failed.')
    } finally {
      setSubmitting(null)
    }
  }

  return (
    <div className="animate-fade-in">
      <div className="flex items-start justify-between mb-8">
        <SectionHeader
          label="Content"
          title="My Series"
          description="Manage your uploaded series and episodes."
        />
        <Link href="/series/new">
          <Button icon={<Plus size={14} />}>New Series</Button>
        </Link>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner size={28} /></div>
      ) : series.length === 0 ? (
        <EmptyState
          icon={<Film />}
          title="No series yet"
          description="Create your first series to get started on VERTX."
          action={
            <Link href="/series/new">
              <Button icon={<Plus size={14} />}>Create First Series</Button>
            </Link>
          }
        />
      ) : (
        <div className="space-y-3">
          {series.map((s) => (
            <Card key={s.id} className="flex items-center gap-4 p-4 hover:border-border/80 transition-all">

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
                  <p className="font-syne font-bold text-base truncate">{s.title}</p>
                  <StatusBadge status={s.status} />
                </div>
                <p className="text-muted text-xs line-clamp-1">{s.description}</p>
                <div className="flex gap-3 mt-1.5">
                  <span className="font-mono text-[0.6rem] text-muted uppercase tracking-widest">{s.genre}</span>
                  <span className="font-mono text-[0.6rem] text-muted">{s.episode_count} episodes</span>
                  <span className="font-mono text-[0.6rem] text-muted">
                    {formatDistanceToNow(new Date(s.updated_at), { addSuffix: true })}
                  </span>
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-2 flex-shrink-0">
                {(s.status === 'draft' || s.status === 'rejected') && (
                  <Button
                    variant="secondary"
                    size="sm"
                    loading={submitting === s.id}
                    icon={<Send size={11} />}
                    onClick={() => handleSubmit(s)}
                  >
                    Submit
                  </Button>
                )}

                {s.status === 'draft' && (
                  <button
                    onClick={() => setDeleteTarget(s)}
                    className="p-2 text-muted hover:text-accent2 transition-colors"
                    title="Delete"
                  >
                    <Trash2 size={14} />
                  </button>
                )}

                <Link
                  href={`/series/${s.id}`}
                  className="p-2 text-muted hover:text-accent3 transition-colors"
                >
                  <ArrowRight size={16} />
                </Link>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Delete confirm modal */}
      <Modal
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        title="Delete Series"
      >
        <p className="text-muted text-sm mb-6">
          Are you sure you want to delete{' '}
          <strong className="text-text">&ldquo;{deleteTarget?.title}&rdquo;</strong>?
          This will also delete all episodes. This cannot be undone.
        </p>
        <div className="flex gap-3 justify-end">
          <Button variant="secondary" onClick={() => setDeleteTarget(null)}>Cancel</Button>
          <Button variant="danger" loading={deleting} onClick={handleDelete}>
            Delete
          </Button>
        </div>
      </Modal>
    </div>
  )
}
