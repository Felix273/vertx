'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { authApi, setAuth } from '@/lib/api'
import { Button, Input } from '@/components/ui'

const schema = z.object({
  full_name:   z.string().min(2, 'Name must be at least 2 characters'),
  studio_name: z.string().min(2, 'Studio name must be at least 2 characters'),
  email:       z.string().email('Invalid email'),
  password:    z.string().min(8, 'Password must be at least 8 characters'),
  password2:   z.string(),
}).refine((d) => d.password === d.password2, {
  message: 'Passwords do not match',
  path: ['password2'],
})
type FormData = z.infer<typeof schema>

export default function RegisterPage() {
  const router  = useRouter()
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      const res = await authApi.register(data)
      setAuth(res.data.tokens.access, res.data.tokens.refresh)
      toast.success('Account created. Welcome to VERTX.')
      router.push('/dashboard')
    } catch (err: unknown) {
      const d = (err as { response?: { data?: Record<string, string[]> } })?.response?.data
      const msg = d ? Object.values(d).flat()[0] : 'Registration failed.'
      toast.error(String(msg))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-black flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-sm animate-fade-in">
        <div className="text-center mb-10">
          <div className="font-syne font-black text-3xl tracking-tight mb-1">
            VERT<span className="text-accent">X</span>
          </div>
          <p className="font-mono text-[0.65rem] text-muted tracking-widest uppercase">
            Create Producer Account
          </p>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <Input label="Full Name" placeholder="Jane Doe" error={errors.full_name?.message} {...register('full_name')} />
          <Input label="Studio Name" placeholder="Nairobi Films" error={errors.studio_name?.message} {...register('studio_name')} />
          <Input label="Email" type="email" placeholder="you@studio.com" error={errors.email?.message} {...register('email')} />
          <Input label="Password" type="password" placeholder="Min. 8 characters" error={errors.password?.message} {...register('password')} />
          <Input label="Confirm Password" type="password" placeholder="Repeat password" error={errors.password2?.message} {...register('password2')} />

          <Button type="submit" loading={loading} className="w-full mt-2" size="lg">
            Create Account
          </Button>
        </form>

        <p className="text-center text-sm text-muted mt-6">
          Already have an account?{' '}
          <Link href="/auth/login" className="text-accent3 hover:text-accent3/80 transition-colors">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  )
}
