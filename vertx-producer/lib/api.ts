/**
 * VERTX API Client
 * Axios instance with JWT attach + automatic token refresh.
 */

import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios'
import Cookies from 'js-cookie'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

export const api = axios.create({
  baseURL: `${BASE_URL}/api`,
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
})

// ── Attach access token to every request ─────────────────────
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = Cookies.get('access_token')
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// ── Refresh token on 401 ──────────────────────────────────────
let refreshing = false
let queue: Array<(token: string) => void> = []

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const original = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    if (error.response?.status === 401 && !original._retry) {
      original._retry = true

      if (refreshing) {
        return new Promise((resolve) => {
          queue.push((token: string) => {
            original.headers.Authorization = `Bearer ${token}`
            resolve(api(original))
          })
        })
      }

      refreshing = true
      const refreshToken = Cookies.get('refresh_token')

      if (!refreshToken) {
        clearAuth()
        window.location.href = '/auth/login'
        return Promise.reject(error)
      }

      try {
        const { data } = await axios.post(`${BASE_URL}/api/auth/token/refresh/`, {
          refresh: refreshToken,
        })

        const newAccess = data.access
        Cookies.set('access_token', newAccess, { expires: 1/24 }) // 1 hour
        queue.forEach((cb) => cb(newAccess))
        queue = []
        refreshing = false

        original.headers.Authorization = `Bearer ${newAccess}`
        return api(original)
      } catch {
        clearAuth()
        window.location.href = '/auth/login'
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  }
)

export function setAuth(access: string, refresh: string) {
  Cookies.set('access_token',  access,  { expires: 1/24 })   // 1 hour
  Cookies.set('refresh_token', refresh, { expires: 7 })       // 7 days
}

export function clearAuth() {
  Cookies.remove('access_token')
  Cookies.remove('refresh_token')
}

export function getAccessToken() {
  return Cookies.get('access_token')
}

// ── Typed API helpers ─────────────────────────────────────────
export const authApi = {
  login:          (email: string, password: string) =>
    api.post('/auth/login/', { email, password }),
  register:       (data: Record<string, string>) =>
    api.post('/auth/register/producer/', data),
  me:             () => api.get('/auth/me/'),
  logout:         (refresh: string) => api.post('/auth/logout/', { refresh }),
  updateProfile:  (data: Record<string, string>) => api.patch('/auth/me/', data),
  studioProfile:  () => api.get('/auth/producer/profile/'),
  updateStudio:   (data: Record<string, unknown>) => api.patch('/auth/producer/profile/', data),
}

export const contentApi = {
  listSeries:     () => api.get('/producer/series/'),
  getSeries:      (id: string) => api.get(`/producer/series/${id}/`),
  createSeries:   (data: Record<string, unknown>) => api.post('/producer/series/', data),
  updateSeries:   (id: string, data: Record<string, unknown>) => api.patch(`/producer/series/${id}/`, data),
  deleteSeries:   (id: string) => api.delete(`/producer/series/${id}/`),
  submitSeries:   (id: string) => api.post(`/producer/series/${id}/submit/`),
  listEpisodes:   (seriesId: string) => api.get(`/producer/series/${seriesId}/episodes/`),
  addEpisode:     (seriesId: string, data: Record<string, unknown>) =>
    api.post(`/producer/series/${seriesId}/episodes/`, data),
  updateEpisode:  (id: string, data: Record<string, unknown>) => api.patch(`/producer/episodes/${id}/`, data),
  deleteEpisode:  (id: string) => api.delete(`/producer/episodes/${id}/`),
}

export const paymentsApi = {
  history: () => api.get('/payments/history/'),
}
