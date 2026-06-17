'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { clsx } from 'clsx'
import {
  LayoutDashboard, Film, CheckSquare, Wallet,
  User, LogOut, ChevronRight, Zap, Shield,
  Users, BarChart3, CreditCard, ClipboardList,
} from 'lucide-react'
import { useAuth } from '@/lib/auth-context'

const PRODUCER_NAV = [
  { href: '/dashboard',  label: 'Dashboard',     icon: LayoutDashboard },
  { href: '/series',     label: 'My Series',     icon: Film },
  { href: '/moderation', label: 'Review Status', icon: CheckSquare },
  { href: '/earnings',   label: 'Earnings',      icon: Wallet },
  { href: '/profile',    label: 'Studio',        icon: User },
]

const ADMIN_NAV = [
  { href: '/admin/stats',    label: 'Platform Stats', icon: BarChart3 },
  { href: '/admin/queue',    label: 'Review Queue',   icon: ClipboardList },
  { href: '/admin/users',    label: 'Users',          icon: Users },
  { href: '/admin/payments', label: 'Payments',       icon: CreditCard },
]

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname  = usePathname()
  const { user, profile, logout } = useAuth()

  return (
    <div className="flex h-screen bg-black overflow-hidden">

      {/* ── Sidebar ─────────────────────────────────────── */}
      <aside className="w-60 flex-shrink-0 bg-surface border-r border-border flex flex-col relative z-10">

        {/* Logo */}
        <div className="px-6 py-5 border-b border-border">
          <div className="font-syne font-black text-xl tracking-tight">
            VERT<span className="text-accent">X</span>
          </div>
          <div className="font-mono text-[0.6rem] text-muted tracking-widest uppercase mt-0.5">
            {user?.role === 'admin' ? 'Admin Portal' : 'Producer Portal'}
          </div>
        </div>

        {/* Studio badge (producers) / Admin badge (admins) */}
        <div className="px-6 py-3 border-b border-border">
          <div className="flex items-center gap-2">
            <div className={`w-7 h-7 flex items-center justify-center text-xs font-mono font-bold ${
              user?.role === 'admin'
                ? 'bg-accent2/20 border border-accent2/30 text-accent2'
                : 'bg-accent3/20 border border-accent3/30 text-accent3'
            }`}>
              {user?.role === 'admin'
                ? <Shield size={12} />
                : profile?.studio_name?.charAt(0).toUpperCase() ?? '?'
              }
            </div>
            <div className="min-w-0">
              <p className="text-xs font-syne font-bold truncate">
                {user?.role === 'admin' ? 'Administrator' : profile?.studio_name ?? '—'}
              </p>
              {user?.role === 'admin' ? (
                <p className="font-mono text-[0.55rem] text-accent2 tracking-widest uppercase flex items-center gap-1">
                  <Shield size={8} /> Full Access
                </p>
              ) : profile?.verified && (
                <p className="font-mono text-[0.55rem] text-green tracking-widest uppercase flex items-center gap-1">
                  <Zap size={8} /> Verified
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">

          {/* Producer nav — always visible */}
          {PRODUCER_NAV.map(({ href, label, icon: Icon }) => {
            const active = pathname === href || pathname.startsWith(href + '/')
            return (
              <Link
                key={href}
                href={href}
                className={clsx(
                  'flex items-center gap-3 px-3 py-2.5 transition-all duration-150 group relative',
                  active
                    ? 'bg-accent/10 text-accent border-l-2 border-accent pl-[10px]'
                    : 'text-muted hover:text-text hover:bg-white/3 border-l-2 border-transparent'
                )}
              >
                <Icon size={16} className="flex-shrink-0" />
                <span className="font-mono text-[0.7rem] tracking-widest uppercase flex-1">{label}</span>
                {active && <ChevronRight size={12} className="opacity-60" />}
              </Link>
            )
          })}

          {/* Admin nav — only visible to admins */}
          {user?.role === 'admin' && (
            <>
              <div className="pt-4 pb-2 px-3">
                <div className="flex items-center gap-2">
                  <span className="w-4 h-px bg-accent2/40" />
                  <p className="font-mono text-[0.55rem] text-accent2 tracking-widest uppercase flex items-center gap-1">
                    <Shield size={8} /> Admin
                  </p>
                  <span className="flex-1 h-px bg-accent2/40" />
                </div>
              </div>
              {ADMIN_NAV.map(({ href, label, icon: Icon }) => {
                const active = pathname === href || pathname.startsWith(href + '/')
                return (
                  <Link
                    key={href}
                    href={href}
                    className={clsx(
                      'flex items-center gap-3 px-3 py-2.5 transition-all duration-150 group relative',
                      active
                        ? 'bg-accent2/10 text-accent2 border-l-2 border-accent2 pl-[10px]'
                        : 'text-muted hover:text-text hover:bg-white/3 border-l-2 border-transparent'
                    )}
                  >
                    <Icon size={16} className="flex-shrink-0" />
                    <span className="font-mono text-[0.7rem] tracking-widest uppercase flex-1">{label}</span>
                    {active && <ChevronRight size={12} className="opacity-60" />}
                  </Link>
                )
              })}
            </>
          )}
        </nav>

        {/* User + logout */}
        <div className="border-t border-border p-4">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 bg-accent3/10 border border-accent3/20 flex items-center justify-center font-mono text-xs text-accent3">
              {user?.full_name?.charAt(0) || '?'}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium truncate">{user?.full_name}</p>
              <p className="font-mono text-[0.6rem] text-muted truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center gap-2 px-3 py-2 text-muted hover:text-accent2 font-mono text-[0.65rem] tracking-widest uppercase transition-colors"
          >
            <LogOut size={13} />
            Sign Out
          </button>
        </div>
      </aside>

      {/* ── Main content ─────────────────────────────────── */}
      <main className="flex-1 overflow-y-auto relative">
        <div className="max-w-5xl mx-auto px-8 py-8">
          {children}
        </div>
      </main>
    </div>
  )
}
