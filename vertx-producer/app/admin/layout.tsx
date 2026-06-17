'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth-context'
import AuthGuard from '@/components/layout/AuthGuard'
import DashboardLayout from '@/components/layout/DashboardLayout'
import { Spinner } from '@/components/ui'

function AdminGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && user && user.role !== 'admin') {
      router.push('/dashboard')
    }
  }, [user, loading, router])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-black">
        <Spinner size={24} />
      </div>
    )
  }

  if (!user || user.role !== 'admin') return null

  return <>{children}</>
}

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <AdminGuard>
        <DashboardLayout>{children}</DashboardLayout>
      </AdminGuard>
    </AuthGuard>
  )
}
