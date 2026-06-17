'use client'

import AuthGuard from '@/components/layout/AuthGuard'
import DashboardLayout from '@/components/layout/DashboardLayout'
import ProducerGuard from '@/components/layout/ProducerGuard'

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <DashboardLayout>
        <ProducerGuard>{children}</ProducerGuard>
      </DashboardLayout>
    </AuthGuard>
  )
}
