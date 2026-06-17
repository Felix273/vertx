'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth-context'

export default function ProducerGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && user && user.role === 'admin') {
      router.replace('/admin/stats')
    }
  }, [user, loading, router])

  if (loading) return null
  if (user?.role === 'admin') return null

  return <>{children}</>
}
