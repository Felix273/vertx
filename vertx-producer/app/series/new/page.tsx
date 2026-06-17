'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { ArrowLeft, Save } from 'lucide-react'
import { contentApi } from '@/lib/api'
import { GENRES } from '@/types'
import { Button, Input, Textarea, Select, Card, SectionHeader } from '@/components/ui'

const schema = z.object({
  title:         z.string().min(2, 'Title is required'),
  description:   z.string().min(20, 'Description must be at least 20 characters'),
  genre:         z.string(),
  thumbnail_url: z.string().url('Must be a valid URL').or(z.literal('')),
  trailer_url:   z.string().url('Must be a valid URL').or(z.literal('')),
  price:         z.string().regex(/^\d+(\.\d{1,2})?$/, 'Invalid price').or(z.literal('')),
  is_free:       z.boolean(),
})
type FormData = z.infer<typeof schema>

export default function NewSeriesPage() {
  const router  = useRouter()
  const [saving, setSaving] = useState(false)

  const { register, handleSubmit, watch, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { genre: 'drama', price: '0', is_free: false },
  })

  const isFree = watch('is_free')

  const onSubmit = async (data: FormData) => {
    setSaving(true)
    try {
      const res = await contentApi.createSeries({
        ...data,
        price: data.price || '0',
      })
      toast.success('Series created. Now add episodes.')
      router.push(`/series/${res.data.id}`)
    } catch (err: unknown) {
      const d = (err as { response?: { data?: Record<string, string[]> } })?.response?.data
      const msg = d ? Object.values(d).flat()[0] : 'Failed to create series.'
      toast.error(String(msg))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="animate-fade-in max-w-2xl">
      <Link href="/series" className="inline-flex items-center gap-2 font-mono text-[0.65rem] text-muted hover:text-text tracking-widest uppercase mb-6 transition-colors">
        <ArrowLeft size={12} /> Back to Series
      </Link>

      <SectionHeader label="Content" title="New Series" description="Fill in the details for your series." />

      <form onSubmit={handleSubmit(onSubmit)}>
        <Card className="p-6 space-y-5">
          <Input label="Title" placeholder="City of Secrets" error={errors.title?.message} {...register('title')} />
          <Textarea label="Description" placeholder="A gripping story about..." error={errors.description?.message} rows={4} {...register('description')} />

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Genre"
              options={GENRES}
              error={errors.genre?.message}
              {...register('genre')}
            />
            <Input label="Thumbnail URL" placeholder="https://..." error={errors.thumbnail_url?.message} {...register('thumbnail_url')} />
          </div>

          <Input label="Trailer URL (optional)" placeholder="https://..." error={errors.trailer_url?.message} {...register('trailer_url')} />

          {/* Pricing */}
          <div className="border border-border p-4 space-y-3">
            <p className="font-mono text-[0.65rem] text-muted tracking-widest uppercase">Pricing</p>
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_free"
                className="accent-accent w-4 h-4"
                {...register('is_free')}
              />
              <label htmlFor="is_free" className="text-sm text-text cursor-pointer">
                Free series (no subscription or purchase required)
              </label>
            </div>
            {!isFree && (
              <Input
                label="Series Price (KES) — leave 0 for subscription-only"
                type="number"
                step="0.01"
                min="0"
                placeholder="0.00"
                error={errors.price?.message}
                {...register('price')}
              />
            )}
          </div>
        </Card>

        <div className="flex gap-3 justify-end mt-4">
          <Link href="/series"><Button variant="secondary">Cancel</Button></Link>
          <Button type="submit" loading={saving} icon={<Save size={14} />}>
            Create Series
          </Button>
        </div>
      </form>
    </div>
  )
}
