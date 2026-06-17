'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { Save, Zap, User } from 'lucide-react'
import { authApi } from '@/lib/api'
import { useAuth } from '@/lib/auth-context'
import { Button, Input, Textarea, Card, SectionHeader } from '@/components/ui'

const schema = z.object({
  studio_name: z.string().min(2),
  bio:         z.string(),
  avatar_url:  z.string().url('Must be a valid URL').or(z.literal('')),
  website:     z.string().url('Must be a valid URL').or(z.literal('')),
})
type FormData = z.infer<typeof schema>

export default function ProfilePage() {
  const { user, profile, refreshProfile } = useAuth()
  const [saving, setSaving] = useState(false)

  const { register, handleSubmit, formState: { errors, isDirty } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      studio_name: profile?.studio_name || '',
      bio:         profile?.bio || '',
      avatar_url:  profile?.avatar_url || '',
      website:     profile?.website || '',
    },
  })

  const onSubmit = async (data: FormData) => {
    setSaving(true)
    try {
      await authApi.updateStudio(data)
      await refreshProfile()
      toast.success('Studio profile updated.')
    } catch {
      toast.error('Failed to update profile.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="animate-fade-in max-w-2xl">
      <SectionHeader
        label="Account"
        title="Studio Profile"
        description="Your public profile on VERTX."
      />

      {/* Account info */}
      <Card className="p-5 mb-6 flex items-center gap-4">
        <div className="w-14 h-14 bg-accent3/10 border border-accent3/20 flex items-center justify-center text-accent3">
          {profile?.avatar_url
            ? <img src={profile.avatar_url} alt="" className="w-full h-full object-cover" />
            : <User size={24} />
          }
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="font-syne font-bold text-base">{user?.full_name}</p>
            {profile?.verified && (
              <span className="font-mono text-[0.6rem] text-green border border-green/30 bg-green/8 px-2 py-0.5 flex items-center gap-1">
                <Zap size={8} /> Verified
              </span>
            )}
          </div>
          <p className="font-mono text-[0.65rem] text-muted mt-0.5">{user?.email}</p>
          <p className="font-mono text-[0.6rem] text-muted mt-0.5 uppercase tracking-widest">
            Producer · Member since {new Date(user?.created_at || '').getFullYear()}
          </p>
        </div>
      </Card>

      {/* Studio form */}
      <form onSubmit={handleSubmit(onSubmit)}>
        <Card className="p-6 space-y-5">
          <Input
            label="Studio Name"
            placeholder="Nairobi Films"
            error={errors.studio_name?.message}
            {...register('studio_name')}
          />
          <Textarea
            label="Bio"
            placeholder="Tell viewers about your studio..."
            rows={4}
            {...register('bio')}
          />
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Avatar URL"
              placeholder="https://..."
              error={errors.avatar_url?.message}
              {...register('avatar_url')}
            />
            <Input
              label="Website"
              placeholder="https://yourstudio.com"
              error={errors.website?.message}
              {...register('website')}
            />
          </div>
        </Card>

        <div className="flex justify-end mt-4">
          <Button
            type="submit"
            loading={saving}
            disabled={!isDirty}
            icon={<Save size={14} />}
          >
            Save Changes
          </Button>
        </div>
      </form>

      {/* Verification */}
      {!profile?.verified && (
        <Card className="mt-6 p-5 border-accent3/20">
          <p className="font-mono text-[0.65rem] text-accent3 tracking-widest uppercase mb-2">Studio Verification</p>
          <p className="text-muted text-sm leading-relaxed">
            Get your studio verified to build trust with viewers on VERTX.
            Contact <strong className="text-text">support@vertx.com</strong> with your studio details.
          </p>
        </Card>
      )}
    </div>
  )
}
