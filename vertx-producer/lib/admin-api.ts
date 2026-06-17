import { api } from '@/lib/api'

export const adminApi = {
  // Stats
  getStats: () => api.get('/admin/stats/'),

  // Moderation queue
  getQueue:      () => api.get('/admin/queue/'),
  approveSeries: (id: string) => api.post(`/admin/series/${id}/approve/`),
  rejectSeries:  (id: string, note: string) =>
    api.post(`/admin/series/${id}/reject/`, { note }),
  getAllSeries:  (status?: string) =>
    api.get('/admin/series/', { params: status ? { status } : {} }),

  // Users
  getUsers:    (role?: string) =>
    api.get('/admin/users/', { params: role ? { role } : {} }),
  toggleUser:  (id: string) => api.post(`/admin/users/${id}/toggle/`),

  // Audit log
  getLog: () => api.get('/admin/log/'),

  // Payments (reuse payments history as admin sees all)
  getPayments: () => api.get('/payments/history/'),
}
