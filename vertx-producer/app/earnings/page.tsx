'use client'

import { useEffect, useState } from 'react'
import { paymentsApi } from '@/lib/api'
import { Payment } from '@/types'
import { Card, Spinner, SectionHeader, EmptyState } from '@/components/ui'
import { Wallet, TrendingUp, CheckCircle, Clock, XCircle } from 'lucide-react'
import { format } from 'date-fns'

const STATUS_CONFIG = {
  success:  { icon: CheckCircle, color: 'text-green',   label: 'Success' },
  pending:  { icon: Clock,       color: 'text-yellow-400', label: 'Pending' },
  failed:   { icon: XCircle,     color: 'text-accent2', label: 'Failed' },
  refunded: { icon: XCircle,     color: 'text-muted',   label: 'Refunded' },
}

export default function EarningsPage() {
  const [payments, setPayments] = useState<Payment[]>([])
  const [loading,  setLoading]  = useState(true)

  useEffect(() => {
    paymentsApi.earnings()
      .then((r) => setPayments(r.data.results ?? r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const totals = {
    success: payments
      .filter((p) => p.status === 'success')
      .reduce((sum, p) => sum + parseFloat(p.amount), 0),
    count: payments.filter((p) => p.status === 'success').length,
  }

  return (
    <div className="animate-fade-in">
      <SectionHeader
        label="Finance"
        title="Earnings"
        description="Your payment history on the VERTX platform."
      />

      {/* Summary cards */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <Card className="p-5">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Total Earned</p>
              <p className="font-syne font-black text-3xl text-accent">
                KES {loading ? '—' : totals.success.toFixed(2)}
              </p>
            </div>
            <TrendingUp size={20} className="text-accent/40 mt-1" />
          </div>
        </Card>

        <Card className="p-5">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-2">Transactions</p>
              <p className="font-syne font-black text-3xl text-text">
                {loading ? '—' : totals.count}
              </p>
            </div>
            <Wallet size={20} className="text-muted/40 mt-1" />
          </div>
        </Card>
      </div>

      {/* M-Pesa info notice */}
      <div className="mb-6 p-4 border border-accent3/20 bg-accent3/5 flex items-start gap-3">
        <div className="w-5 h-5 bg-accent3/20 border border-accent3/30 flex items-center justify-center text-accent3 text-[0.6rem] font-mono flex-shrink-0 mt-0.5">
          ₿
        </div>
        <div>
          <p className="font-mono text-[0.65rem] text-accent3 tracking-widest uppercase mb-1">M-Pesa Payments</p>
          <p className="text-muted text-xs leading-relaxed">
            All transactions are processed via Safaricom M-Pesa (Daraja API).
            Payouts are settled to your registered M-Pesa number on a weekly basis.
          </p>
        </div>
      </div>

      {/* Transactions table */}
      <div>
        <h2 className="font-syne font-bold text-base mb-4">Transaction History</h2>

        {loading ? (
          <div className="flex justify-center py-12"><Spinner /></div>
        ) : payments.length === 0 ? (
          <EmptyState
            icon={<Wallet />}
            title="No transactions yet"
            description="Earnings will appear here once viewers purchase or subscribe."
          />
        ) : (
          <Card>
            {/* Header */}
            <div className="grid grid-cols-4 px-4 py-2 border-b border-border">
              {['Date', 'Provider', 'Amount', 'Status'].map((h) => (
                <span key={h} className="font-mono text-[0.6rem] text-muted tracking-widest uppercase">{h}</span>
              ))}
            </div>

            {payments.map((p, i) => {
              const cfg = STATUS_CONFIG[p.status] || STATUS_CONFIG.pending
              const StatusIcon = cfg.icon
              return (
                <div
                  key={p.id}
                  className={`grid grid-cols-4 items-center px-4 py-3 ${
                    i < payments.length - 1 ? 'border-b border-border' : ''
                  } hover:bg-white/1 transition-colors`}
                >
                  <span className="font-mono text-xs text-muted">
                    {format(new Date(p.created_at), 'd MMM yyyy')}
                  </span>
                  <span className="font-mono text-xs text-text uppercase">{p.provider}</span>
                  <span className="font-mono text-xs text-text font-bold">
                    {p.currency} {parseFloat(p.amount).toFixed(2)}
                  </span>
                  <div className="flex items-center gap-1.5">
                    <StatusIcon size={12} className={cfg.color} />
                    <span className={`font-mono text-[0.65rem] ${cfg.color}`}>{cfg.label}</span>
                  </div>
                </div>
              )
            })}
          </Card>
        )}
      </div>
    </div>
  )
}
