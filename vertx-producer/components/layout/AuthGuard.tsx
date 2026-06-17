'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth-context'
import { Spinner } from '@/components/ui'

export default function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.push('/auth/login')
    }
    if (!loading && user && user.role !== 'producer' && user.role !== 'admin') {
      router.push('/auth/login?error=not_producer')
    }
  }, [user, loading, router])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-black">
        <div className="flex flex-col items-center gap-4">
          <div className="font-syne font-black text-2xl tracking-tight">
            VERT<span className="text-accent">X</span>
          </div>
          <Spinner size={24} />
        </div>
      </div>
    )
  }

  if (!user || (user.role !== 'producer' && user.role !== 'admin')) return null

  return <>{children}</>
}
