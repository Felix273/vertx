'use client'

import { useEffect, useState } from 'react'
import { CreditCard, TrendingUp, CheckCircle, XCircle, Clock, RefreshCw } from 'lucide-react'
import { adminApi } from '@/lib/admin-api'
import { Card, Spinner, SectionHeader, EmptyState } from '@/components/ui'
import { formatDistanceToNow } from 'date-fns'

interface Payment {
  id:           string
  user_email:   string
  user_name:    string
  provider:     string
  amount:       string
  currency:     string
  status:       string
  payment_type: string
  series_title?: string
  created_at:   string
}

const STATUS_STYLES: Record<string, string> = {
  success:  'text-green',
  pending:  'text-yellow-400',
  failed:   'text-accent2',
  refunded: 'text-accent3',
}

const STATUS_ICONS: Record<string, React.ElementType> = {
  success:  CheckCircle,
  pending:  Clock,
  failed:   XCircle,
  refunded: RefreshCw,
}

export default function AdminPaymentsPage() {
  const [payments, setPayments] = useState<Payment[]>([])
  const [loading,  setLoading]  = useState(true)
  const [filter,   setFilter]   = useState('all')

  useEffect(() => {
    adminApi.getPayments()
      .then((r) => setPayments(r.data.results ?? r.data))
      .catch(() => setPayments([]))
      .finally(() => setLoading(false))
  }, [])

  const filtered = filter === 'all'
    ? payments
    : payments.filter((p) => p.status === filter)

  const totalRevenue = payments
    .filter((p) => p.status === 'success')
    .reduce((sum, p) => sum + parseFloat(p.amount), 0)

  const counts = {
    all:      payments.length,
    success:  payments.filter((p) => p.status === 'success').length,
    pending:  payments.filter((p) => p.status === 'pending').length,
    failed:   payments.filter((p) => p.status === 'failed').length,
  }

  return (
    <div className="animate-fade-in">
      <SectionHeader
        label="Admin"
        title="All Payments"
        description="Platform-wide transaction history."
      />

      {/* Summary cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        <Card className="p-4">
          <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Total Revenue</p>
          <p className="font-syne font-black text-2xl text-accent">
            KES {loading ? '—' : totalRevenue.toLocaleString()}
          </p>
        </Card>
        <Card className="p-4">
          <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Successful</p>
          <p className="font-syne font-black text-2xl text-green">{loading ? '—' : counts.success}</p>
        </Card>
        <Card className="p-4">
          <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Pending</p>
          <p className="font-syne font-black text-2xl text-yellow-400">{loading ? '—' : counts.pending}</p>
        </Card>
        <Card className="p-4">
          <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Failed</p>
          <p className="font-syne font-black text-2xl text-accent2">{loading ? '—' : counts.failed}</p>
        </Card>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-0 border-b border-border mb-4">
        {['all', 'success', 'pending', 'failed'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2.5 font-mono text-[0.65rem] tracking-widest uppercase border-b-2 transition-colors flex items-center gap-2 ${
              filter === f
                ? 'text-accent2 border-accent2'
                : 'text-muted border-transparent hover:text-text'
            }`}
          >
            {f}
            <span className={`text-[0.55rem] px-1.5 py-0.5 ${
              filter === f ? 'bg-accent2/20 text-accent2' : 'bg-border text-muted'
            }`}>
              {counts[f as keyof typeof counts] ?? payments.length}
            </span>
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner size={28} /></div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<CreditCard />}
          title="No payments yet"
          description="Transactions will appear here once users subscribe or purchase."
        />
      ) : (
        <Card>
          {/* Table header */}
          <div className="grid grid-cols-12 px-4 py-2 border-b border-border">
            {[
              { label: 'User',     span: 'col-span-3' },
              { label: 'Type',     span: 'col-span-2' },
              { label: 'Amount',   span: 'col-span-2' },
              { label: 'Provider', span: 'col-span-2' },
              { label: 'Status',   span: 'col-span-2' },
              { label: 'Date',     span: 'col-span-1' },
            ].map(({ label, span }) => (
              <span key={label} className={`font-mono text-[0.6rem] text-muted tracking-widest uppercase ${span}`}>
                {label}
              </span>
            ))}
          </div>

          {filtered.map((p, i) => {
            const StatusIcon = STATUS_ICONS[p.status] || Clock
            return (
              <div
                key={p.id}
                className={`grid grid-cols-12 items-center px-4 py-3 ${
                  i < filtered.length - 1 ? 'border-b border-border' : ''
                } hover:bg-white/1 transition-colors`}
              >
                {/* User */}
                <div className="col-span-3 min-w-0">
                  <p className="text-sm font-medium truncate">{p.user_name}</p>
                  <p className="font-mono text-[0.6rem] text-muted truncate">{p.user_email}</p>
                </div>

                {/* Type */}
                <div className="col-span-2">
                  <span className="font-mono text-[0.6rem] tracking-widest uppercase text-muted">
                    {p.payment_type}
                    {p.series_title && (
                      <span className="block text-text/60 truncate max-w-24">{p.series_title}</span>
                    )}
                  </span>
                </div>

                {/* Amount */}
                <div className="col-span-2">
                  <span className="font-syne font-bold text-sm text-accent">
                    {p.currency} {parseFloat(p.amount).toLocaleString()}
                  </span>
                </div>

                {/* Provider */}
                <div className="col-span-2">
                  <span className="font-mono text-[0.6rem] tracking-widest uppercase text-muted">
                    {p.provider}
                  </span>
                </div>

                {/* Status */}
                <div className="col-span-2">
                  <span className={`flex items-center gap-1 font-mono text-[0.6rem] tracking-widest uppercase ${STATUS_STYLES[p.status] || 'text-muted'}`}>
                    <StatusIcon size={10} />
                    {p.status}
                  </span>
                </div>

                {/* Date */}
                <div className="col-span-1">
                  <span className="font-mono text-[0.55rem] text-muted">
                    {formatDistanceToNow(new Date(p.created_at), { addSuffix: true })}
                  </span>
                </div>
              </div>
            )
          })}
        </Card>
      )}
    </div>
  )
}
