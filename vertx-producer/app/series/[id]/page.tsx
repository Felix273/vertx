'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import toast from 'react-hot-toast'
import {
  ArrowLeft, Plus, Trash2, Edit2, Send, Clock,
  Film, CheckCircle, Save, X
} from 'lucide-react'
import { contentApi } from '@/lib/api'
import { Series, Episode } from '@/types'
import {
  Button, Card, StatusBadge, Spinner, SectionHeader, Input, Textarea, Modal
} from '@/components/ui'

function EpisodeRow({
  episode, onDelete, onUpdate
}: {
  episode:  Episode
  onDelete: (id: string) => void
  onUpdate: (id: string, data: Partial<Episode>) => void
}) {
  const [editing, setEditing] = useState(false)
  const [saving,  setSaving]  = useState(false)
  const { register, handleSubmit } = useForm({
    defaultValues: {
      title:          episode.title,
      video_url:      episode.video_url,
      duration_secs:  episode.duration_secs,
      description:    episode.description,
    },
  })

  const onSave = async (data: Record<string, unknown>) => {
    setSaving(true)
    try {
      await contentApi.updateEpisode(episode.id, data)
      onUpdate(episode.id, data as Partial<Episode>)
      toast.success('Episode updated.')
      setEditing(false)
    } catch { toast.error('Update failed.') }
    finally { setSaving(false) }
  }

  if (editing) {
    return (
      <Card className="p-4 border-accent3/40">
        <form onSubmit={handleSubmit(onSave)} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <Input label="Title" {...register('title')} />
            <Input label="Video URL (CDN)" {...register('video_url')} />
          </div>
          <Input label="Duration (seconds)" type="number" {...register('duration_secs', { valueAsNumber: true })} />
          <Textarea label="Description (optional)" rows={2} {...register('description')} />
          <div className="flex gap-2 justify-end">
            <Button variant="ghost" size="sm" type="button" onClick={() => setEditing(false)} icon={<X size={12} />}>Cancel</Button>
            <Button size="sm" type="submit" loading={saving} icon={<Save size={12} />}>Save</Button>
          </div>
        </form>
      </Card>
    )
  }

  return (
    <Card className="flex items-center gap-4 p-3 hover:border-border/80 transition-colors">
      <div className="w-8 h-8 bg-surface border border-border flex items-center justify-center font-mono text-xs text-muted flex-shrink-0">
        {episode.episode_number}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">{episode.title}</p>
        <div className="flex gap-3 mt-0.5">
          <span className="font-mono text-[0.6rem] text-muted flex items-center gap-1">
            <Clock size={9} /> {episode.duration_display || `${Math.floor(episode.duration_secs/60)}:${String(episode.duration_secs%60).padStart(2,'0')}`}
          </span>
          {episode.video_url && (
            <span className="font-mono text-[0.6rem] text-green flex items-center gap-1">
              <CheckCircle size={9} /> Video set
            </span>
          )}
        </div>
      </div>
      <div className="flex gap-1">
        <button onClick={() => setEditing(true)} className="p-1.5 text-muted hover:text-accent3 transition-colors">
          <Edit2 size={13} />
        </button>
        <button onClick={() => onDelete(episode.id)} className="p-1.5 text-muted hover:text-accent2 transition-colors">
          <Trash2 size={13} />
        </button>
      </div>
    </Card>
  )
}

export default function SeriesDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router  = useRouter()

  const [series,      setSeries]     = useState<Series | null>(null)
  const [episodes,    setEpisodes]   = useState<Episode[]>([])
  const [loading,     setLoading]    = useState(true)
  const [submitting,  setSubmitting] = useState(false)
  const [addingEp,    setAddingEp]   = useState(false)
  const [savingEp,    setSavingEp]   = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm({
    defaultValues: { episode_number: 1, title: '', video_url: '', duration_secs: 0, description: '' }
  })

  useEffect(() => {
    Promise.all([
      contentApi.getSeries(id),
      contentApi.listEpisodes(id),
    ]).then(([s, e]) => {
      setSeries(s.data)
      const epList = e.data.results ?? e.data
      setEpisodes(epList)
      reset({ episode_number: epList.length + 1, title: '', video_url: '', duration_secs: 0, description: '' })
    }).catch(() => router.push('/series'))
    .finally(() => setLoading(false))
  }, [id])

  const handleSubmitForReview = async () => {
    if (!series) return
    setSubmitting(true)
    try {
      await contentApi.submitSeries(id)
      toast.success('Submitted for review.')
      setSeries((p) => p ? { ...p, status: 'pending_review' } : p)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error
      toast.error(msg || 'Submission failed.')
    } finally { setSubmitting(false) }
  }

  const handleAddEpisode = async (data: Record<string, unknown>) => {
    setSavingEp(true)
    try {
      const res = await contentApi.addEpisode(id, data)
      setEpisodes((prev) => [...prev, res.data].sort((a, b) => a.episode_number - b.episode_number))
      toast.success(`Episode ${data.episode_number} added.`)
      setAddingEp(false)
      reset({ episode_number: episodes.length + 2, title: '', video_url: '', duration_secs: 0, description: '' })
    } catch (err: unknown) {
      const d = (err as { response?: { data?: Record<string, string[]> } })?.response?.data
      toast.error(d ? Object.values(d).flat()[0] as string : 'Failed to add episode.')
    } finally { setSavingEp(false) }
  }

  const handleDeleteEpisode = async (epId: string) => {
    try {
      await contentApi.deleteEpisode(epId)
      setEpisodes((p) => p.filter((e) => e.id !== epId))
      toast.success('Episode deleted.')
    } catch { toast.error('Delete failed.') }
  }

  const handleUpdateEpisode = (epId: string, data: Partial<Episode>) => {
    setEpisodes((p) => p.map((e) => e.id === epId ? { ...e, ...data } : e))
  }

  if (loading) return <div className="flex justify-center py-20"><Spinner size={28} /></div>
  if (!series) return null

  const canSubmit = series.status === 'draft' || series.status === 'rejected'
  const canEdit   = series.status !== 'published'

  return (
    <div className="animate-fade-in">
      <Link href="/series" className="inline-flex items-center gap-2 font-mono text-[0.65rem] text-muted hover:text-text tracking-widest uppercase mb-6 transition-colors">
        <ArrowLeft size={12} /> My Series
      </Link>

      {/* Header */}
      <div className="flex items-start gap-4 mb-8">
        <div className="w-20 h-20 bg-surface border border-border flex-shrink-0 flex items-center justify-center text-muted">
          {series.thumbnail_url
            ? <img src={series.thumbnail_url} alt="" className="w-full h-full object-cover" />
            : <Film size={28} />
          }
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="font-syne font-black text-2xl tracking-tight">{series.title}</h1>
            <StatusBadge status={series.status} />
          </div>
          <p className="text-muted text-sm mt-1 line-clamp-2">{series.description}</p>
          <div className="flex gap-3 mt-2">
            <span className="font-mono text-[0.6rem] text-muted uppercase">{series.genre}</span>
            <span className="font-mono text-[0.6rem] text-muted">{episodes.length} episodes</span>
            {series.is_free
              ? <span className="font-mono text-[0.6rem] text-green">Free</span>
              : <span className="font-mono text-[0.6rem] text-muted">KES {series.price}</span>
            }
          </div>
        </div>
        {canSubmit && (
          <Button
            loading={submitting}
            icon={<Send size={14} />}
            onClick={handleSubmitForReview}
            disabled={episodes.length === 0}
          >
            Submit for Review
          </Button>
        )}
      </div>

      {series.status === 'rejected' && (
        <div className="mb-6 p-4 border border-accent2/30 bg-accent2/5">
          <p className="font-mono text-xs text-accent2 mb-1 uppercase tracking-widest">Rejected</p>
          <p className="text-sm text-muted">Review the rejection feedback, make your edits, and resubmit.</p>
        </div>
      )}

      {episodes.length === 0 && canSubmit && (
        <div className="mb-4 p-3 border border-yellow-400/20 bg-yellow-400/5">
          <p className="font-mono text-xs text-yellow-400">Add at least one episode before submitting.</p>
        </div>
      )}

      {/* Episodes */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <SectionHeader label="Content" title="Episodes" />
          {canEdit && (
            <Button size="sm" icon={<Plus size={13} />} onClick={() => setAddingEp(true)}>
              Add Episode
            </Button>
          )}
        </div>

        <div className="space-y-2">
          {episodes.map((ep) => (
            <EpisodeRow
              key={ep.id}
              episode={ep}
              onDelete={handleDeleteEpisode}
              onUpdate={handleUpdateEpisode}
            />
          ))}
          {episodes.length === 0 && (
            <Card className="p-8 text-center">
              <p className="font-syne font-bold text-sm mb-1">No episodes yet</p>
              <p className="text-muted text-xs">Add episodes to this series.</p>
            </Card>
          )}
        </div>
      </div>

      {/* Add Episode Modal */}
      <Modal open={addingEp} onClose={() => setAddingEp(false)} title="Add Episode">
        <form onSubmit={handleSubmit(handleAddEpisode as Parameters<typeof handleSubmit>[0])} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <Input
              label="Episode Number"
              type="number"
              min={1}
              {...register('episode_number', { required: true, valueAsNumber: true })}
            />
            <Input label="Title" placeholder="Episode 1" {...register('title', { required: true })} />
          </div>
          <Input
            label="Video URL"
            placeholder="https://cloudflarestream.com/..."
            hint="Upload to Cloudflare Stream first, paste the URL here."
            {...register('video_url', { required: true })}
          />
          <Input
            label="Duration (seconds)"
            type="number"
            min={0}
            placeholder="90"
            {...register('duration_secs', { valueAsNumber: true })}
          />
          <Textarea label="Description (optional)" rows={2} {...register('description')} />
          <div className="flex gap-3 justify-end pt-2">
            <Button variant="secondary" type="button" onClick={() => setAddingEp(false)}>Cancel</Button>
            <Button type="submit" loading={savingEp} icon={<Plus size={13} />}>Add Episode</Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
