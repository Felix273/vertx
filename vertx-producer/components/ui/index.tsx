'use client'

import React from 'react'
import { clsx } from 'clsx'
import { Loader2, X } from 'lucide-react'
import { ContentStatus, STATUS_LABELS, STATUS_COLORS } from '@/types'

// ── Button ────────────────────────────────────────────────────
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:  'primary' | 'secondary' | 'danger' | 'ghost'
  size?:     'sm' | 'md' | 'lg'
  loading?:  boolean
  icon?:     React.ReactNode
}

export function Button({
  variant = 'primary', size = 'md', loading, icon,
  children, className, disabled, ...props
}: ButtonProps) {
  const base = 'inline-flex items-center justify-center gap-2 font-mono text-xs tracking-widest uppercase transition-all duration-150 disabled:opacity-40 disabled:cursor-not-allowed border'

  const variants = {
    primary:   'bg-accent text-black border-accent hover:bg-accent/90',
    secondary: 'bg-transparent text-text border-border hover:border-accent3 hover:text-accent3',
    danger:    'bg-transparent text-accent2 border-accent2/40 hover:bg-accent2/10',
    ghost:     'bg-transparent text-muted border-transparent hover:text-text',
  }

  const sizes = {
    sm: 'px-3 py-1.5 text-[0.6rem]',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-[0.8rem]',
  }

  return (
    <button
      className={clsx(base, variants[variant], sizes[size], className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? <Loader2 size={14} className="animate-spin" /> : icon}
      {children}
    </button>
  )
}

// ── Input ─────────────────────────────────────────────────────
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?:  string
  error?:  string
  hint?:   string
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, hint, className, ...props }, ref) => (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label className="font-mono text-[0.65rem] tracking-widest uppercase text-muted">
          {label}
        </label>
      )}
      <input
        ref={ref}
        className={clsx(
          'w-full bg-surface border px-3 py-2.5 text-sm text-text placeholder:text-muted/50',
          'focus:outline-none focus:border-accent3 transition-colors',
          error ? 'border-accent2' : 'border-border',
          className
        )}
        {...props}
      />
      {error && <p className="text-accent2 text-xs font-mono">{error}</p>}
      {hint && !error && <p className="text-muted text-xs">{hint}</p>}
    </div>
  )
)
Input.displayName = 'Input'

// ── Textarea ──────────────────────────────────────────────────
interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  error?: string
}

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, className, ...props }, ref) => (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label className="font-mono text-[0.65rem] tracking-widest uppercase text-muted">
          {label}
        </label>
      )}
      <textarea
        ref={ref}
        rows={4}
        className={clsx(
          'w-full bg-surface border px-3 py-2.5 text-sm text-text placeholder:text-muted/50 resize-none',
          'focus:outline-none focus:border-accent3 transition-colors',
          error ? 'border-accent2' : 'border-border',
          className
        )}
        {...props}
      />
      {error && <p className="text-accent2 text-xs font-mono">{error}</p>}
    </div>
  )
)
Textarea.displayName = 'Textarea'

// ── Select ────────────────────────────────────────────────────
interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?:   string
  error?:   string
  options:  { value: string; label: string }[]
}

export const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, options, className, ...props }, ref) => (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label className="font-mono text-[0.65rem] tracking-widest uppercase text-muted">
          {label}
        </label>
      )}
      <select
        ref={ref}
        className={clsx(
          'w-full bg-surface border px-3 py-2.5 text-sm text-text',
          'focus:outline-none focus:border-accent3 transition-colors appearance-none cursor-pointer',
          error ? 'border-accent2' : 'border-border',
          className
        )}
        {...props}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value} className="bg-surface">
            {o.label}
          </option>
        ))}
      </select>
      {error && <p className="text-accent2 text-xs font-mono">{error}</p>}
    </div>
  )
)
Select.displayName = 'Select'

// ── Card ──────────────────────────────────────────────────────
export function Card({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={clsx('bg-card border border-border', className)}>
      {children}
    </div>
  )
}

// ── StatusBadge ───────────────────────────────────────────────
export function StatusBadge({ status }: { status: ContentStatus }) {
  return (
    <span className={clsx(
      'inline-block font-mono text-[0.6rem] tracking-widest uppercase px-2 py-0.5 border',
      STATUS_COLORS[status]
    )}>
      {STATUS_LABELS[status]}
    </span>
  )
}

// ── Spinner ───────────────────────────────────────────────────
export function Spinner({ size = 20 }: { size?: number }) {
  return <Loader2 size={size} className="animate-spin text-accent3" />
}

// ── Empty State ───────────────────────────────────────────────
export function EmptyState({
  icon, title, description, action
}: {
  icon?: React.ReactNode
  title: string
  description?: string
  action?: React.ReactNode
}) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center px-4">
      {icon && <div className="text-4xl mb-4 opacity-40">{icon}</div>}
      <p className="font-syne font-bold text-lg text-text mb-2">{title}</p>
      {description && <p className="text-muted text-sm max-w-sm">{description}</p>}
      {action && <div className="mt-6">{action}</div>}
    </div>
  )
}

// ── Modal ─────────────────────────────────────────────────────
export function Modal({
  open, onClose, title, children, maxWidth = 'max-w-lg'
}: {
  open:      boolean
  onClose:   () => void
  title:     string
  children:  React.ReactNode
  maxWidth?: string
}) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-sm" onClick={onClose} />
      <div className={clsx('relative w-full bg-card border border-border z-10 animate-fade-in', maxWidth)}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="font-syne font-bold text-base">{title}</h2>
          <button onClick={onClose} className="text-muted hover:text-text transition-colors p-1">
            <X size={18} />
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  )
}

// ── Section Header ────────────────────────────────────────────
export function SectionHeader({
  label, title, description
}: {
  label?: string
  title: string
  description?: string
}) {
  return (
    <div className="mb-8">
      {label && (
        <p className="font-mono text-[0.65rem] tracking-widest uppercase text-accent mb-2 flex items-center gap-2">
          <span className="w-6 h-px bg-accent inline-block" />
          {label}
        </p>
      )}
      <h1 className="font-syne font-bold text-2xl tracking-tight">{title}</h1>
      {description && <p className="text-muted text-sm mt-1">{description}</p>}
    </div>
  )
}
