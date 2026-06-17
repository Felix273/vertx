'use client'

import React, { createContext, useContext, useEffect, useState, useCallback } from 'react'
import Cookies from 'js-cookie'
import { authApi, setAuth, clearAuth } from '@/lib/api'
import type { User, ProducerProfile } from '@/types'

interface AuthState {
  user:           User | null
  profile:        ProducerProfile | null
  loading:        boolean
  login:          (email: string, password: string) => Promise<void>
  logout:         () => Promise<void>
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user,    setUser]    = useState<User | null>(null)
  const [profile, setProfile] = useState<ProducerProfile | null>(null)
  const [loading, setLoading] = useState(true)

  const loadUser = useCallback(async () => {
    const token = Cookies.get('access_token')
    if (!token) { setLoading(false); return }

    try {
      const [meRes, profileRes] = await Promise.all([
        authApi.me(),
        authApi.studioProfile().catch(() => null),
      ])
      setUser(meRes.data)
      if (profileRes) setProfile(profileRes.data)
    } catch {
      clearAuth()
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadUser() }, [loadUser])

  const login = async (email: string, password: string) => {
    const { data } = await authApi.login(email, password)
    setAuth(data.access, data.refresh)
    await loadUser()
  }

  const logout = async () => {
    const refresh = Cookies.get('refresh_token')
    if (refresh) {
      try { await authApi.logout(refresh) } catch { /* ignore */ }
    }
    clearAuth()
    setUser(null)
    setProfile(null)
    window.location.href = '/auth/login'
  }

  const refreshProfile = async () => {
    try {
      const res = await authApi.studioProfile()
      setProfile(res.data)
    } catch { /* ignore */ }
  }

  return (
    <AuthContext.Provider value={{ user, profile, loading, login, logout, refreshProfile }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
