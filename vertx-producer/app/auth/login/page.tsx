'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { useAuth } from '@/lib/auth-context'
import { Button, Input } from '@/components/ui'

const schema = z.object({
  email:    z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
})
type FormData = z.infer<typeof schema>

export default function LoginPage() {
  const { login } = useAuth()
  const router     = useRouter()
  const params     = useSearchParams()
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      await login(data.email, data.password)
      toast.success('Welcome back.')
      router.push('/dashboard')
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail
      toast.error(msg || 'Invalid credentials.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-black flex items-center justify-center px-4">
      <div className="w-full max-w-sm animate-fade-in">

        {/* Logo */}
        <div className="text-center mb-10">
          <div className="font-syne font-black text-3xl tracking-tight mb-1">
            VERT<span className="text-accent">X</span>
          </div>
          <p className="font-mono text-[0.65rem] text-muted tracking-widest uppercase">
            Producer Portal
          </p>
        </div>

        {params.get('error') === 'not_producer' && (
          <div className="mb-6 p-3 border border-accent2/30 bg-accent2/5">
            <p className="font-mono text-xs text-accent2">This portal is for producers only.</p>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <Input
            label="Email"
            type="email"
            placeholder="studio@example.com"
            error={errors.email?.message}
            {...register('email')}
          />
          <Input
            label="Password"
            type="password"
            placeholder="••••••••"
            error={errors.password?.message}
            {...register('password')}
          />
          <Button type="submit" loading={loading} className="w-full mt-2" size="lg">
            Sign In
          </Button>
        </form>

        <p className="text-center text-sm text-muted mt-6">
          New to VERTX?{' '}
          <Link href="/auth/register" className="text-accent3 hover:text-accent3/80 transition-colors">
            Create producer account
          </Link>
        </p>
      </div>
    </div>
  )
}
