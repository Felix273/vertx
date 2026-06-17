'use client'

import { useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import { Users, Shield, Eye, ToggleLeft, ToggleRight, Search } from 'lucide-react'
import { adminApi } from '@/lib/admin-api'
import { Card, Spinner, SectionHeader, EmptyState, Button } from '@/components/ui'
import { formatDistanceToNow } from 'date-fns'

interface AdminUser {
  id:         string
  email:      string
  full_name:  string
  role:       string
  is_active:  boolean
  created_at: string
}

const ROLE_COLORS: Record<string, string> = {
  admin:    'text-accent2 border-accent2/30 bg-accent2/8',
  producer: 'text-accent3 border-accent3/30 bg-accent3/8',
  viewer:   'text-muted border-border',
}

const ROLE_ICONS: Record<string, React.ElementType> = {
  admin:    Shield,
  producer: Eye,
  viewer:   Users,
}

export default function AdminUsersPage() {
  const [users,   setUsers]   = useState<AdminUser[]>([])
  const [loading, setLoading] = useState(true)
  const [filter,  setFilter]  = useState<string>('all')
  const [search,  setSearch]  = useState('')
  const [toggling, setToggling] = useState<string | null>(null)

  const load = (role?: string) => {
    setLoading(true)
    adminApi.getUsers(role === 'all' ? undefined : role)
      .then((r) => setUsers(r.data.results ?? r.data))
      .catch(() => toast.error('Failed to load users.'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const handleFilterChange = (f: string) => {
    setFilter(f)
    load(f)
  }

  const handleToggle = async (user: AdminUser) => {
    setToggling(user.id)
    try {
      await adminApi.toggleUser(user.id)
      toast.success(`${user.full_name} ${user.is_active ? 'suspended' : 'reactivated'}.`)
      setUsers((prev) => prev.map((u) =>
        u.id === user.id ? { ...u, is_active: !u.is_active } : u
      ))
    } catch { toast.error('Failed to update user.') }
    finally { setToggling(null) }
  }

  const filtered = users.filter((u) =>
    search === '' ||
    u.full_name.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  )

  const counts = {
    all:      users.length,
    admin:    users.filter((u) => u.role === 'admin').length,
    producer: users.filter((u) => u.role === 'producer').length,
    viewer:   users.filter((u) => u.role === 'viewer').length,
  }

  return (
    <div className="animate-fade-in">
      <SectionHeader
        label="Admin"
        title="User Management"
        description="View and manage all platform users."
      />

      {/* Stats row */}
      <div className="grid grid-cols-4 gap-3 mb-6">
        {[
          { label: 'Total',     value: counts.all,      color: 'text-text' },
          { label: 'Admins',    value: counts.admin,    color: 'text-accent2' },
          { label: 'Producers', value: counts.producer, color: 'text-accent3' },
          { label: 'Viewers',   value: counts.viewer,   color: 'text-muted' },
        ].map(({ label, value, color }) => (
          <Card key={label} className="p-3 text-center">
            <p className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mb-1">{label}</p>
            <p className={`font-syne font-black text-2xl ${color}`}>{loading ? '—' : value}</p>
          </Card>
        ))}
      </div>

      {/* Search + filter */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <div className="relative flex-1 min-w-48">
          <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name or email..."
            className="w-full bg-surface border border-border pl-8 pr-3 py-2 text-sm text-text placeholder:text-muted/50 focus:outline-none focus:border-accent3"
          />
        </div>
        <div className="flex gap-1">
          {['all', 'admin', 'producer', 'viewer'].map((f) => (
            <button
              key={f}
              onClick={() => handleFilterChange(f)}
              className={`px-3 py-2 font-mono text-[0.65rem] tracking-widest uppercase border transition-colors ${
                filter === f
                  ? 'bg-accent3/10 border-accent3 text-accent3'
                  : 'border-border text-muted hover:text-text'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* User list */}
      {loading ? (
        <div className="flex justify-center py-20"><Spinner size={28} /></div>
      ) : filtered.length === 0 ? (
        <EmptyState icon={<Users />} title="No users found" />
      ) : (
        <Card>
          {/* Header */}
          <div className="grid grid-cols-12 px-4 py-2 border-b border-border">
            {['User', 'Role', 'Status', 'Joined', 'Action'].map((h, i) => (
              <span key={h} className={`font-mono text-[0.6rem] text-muted tracking-widest uppercase ${
                i === 0 ? 'col-span-4' : i === 4 ? 'col-span-2 text-right' : 'col-span-2'
              }`}>
                {h}
              </span>
            ))}
          </div>

          {filtered.map((u, i) => {
            const RoleIcon = ROLE_ICONS[u.role] || Users
            return (
              <div
                key={u.id}
                className={`grid grid-cols-12 items-center px-4 py-3 ${
                  i < filtered.length - 1 ? 'border-b border-border' : ''
                } hover:bg-white/1 transition-colors ${!u.is_active ? 'opacity-50' : ''}`}
              >
                {/* User */}
                <div className="col-span-4 flex items-center gap-3 min-w-0">
                  <div className="w-8 h-8 bg-accent3/10 border border-accent3/20 flex items-center justify-center font-mono text-xs text-accent3 flex-shrink-0">
                    {u.full_name.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate">{u.full_name}</p>
                    <p className="font-mono text-[0.6rem] text-muted truncate">{u.email}</p>
                  </div>
                </div>

                {/* Role */}
                <div className="col-span-2">
                  <span className={`inline-flex items-center gap-1 font-mono text-[0.6rem] tracking-widest uppercase px-2 py-0.5 border ${ROLE_COLORS[u.role] || 'text-muted border-border'}`}>
                    <RoleIcon size={8} />
                    {u.role}
                  </span>
                </div>

                {/* Status */}
                <div className="col-span-2">
                  <span className={`font-mono text-[0.6rem] tracking-widest uppercase ${u.is_active ? 'text-green' : 'text-accent2'}`}>
                    {u.is_active ? 'Active' : 'Suspended'}
                  </span>
                </div>

                {/* Joined */}
                <div className="col-span-2">
                  <span className="font-mono text-[0.6rem] text-muted">
                    {formatDistanceToNow(new Date(u.created_at), { addSuffix: true })}
                  </span>
                </div>

                {/* Action */}
                <div className="col-span-2 flex justify-end">
                  {u.role !== 'admin' && (
                    <button
                      onClick={() => handleToggle(u)}
                      disabled={toggling === u.id}
                      className={`flex items-center gap-1 font-mono text-[0.6rem] tracking-widest uppercase transition-colors ${
                        u.is_active
                          ? 'text-accent2 hover:text-accent2/80'
                          : 'text-green hover:text-green/80'
                      }`}
                    >
                      {u.is_active
                        ? <><ToggleRight size={14} /> Suspend</>
                        : <><ToggleLeft size={14} /> Activate</>
                      }
                    </button>
                  )}
                </div>
              </div>
            )
          })}
        </Card>
      )}
    </div>
  )
}
