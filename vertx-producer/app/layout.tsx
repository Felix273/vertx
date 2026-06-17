import type { Metadata } from 'next'
import { Syne, Space_Mono, DM_Sans } from 'next/font/google'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from '@/lib/auth-context'
import './globals.css'

const syne = Syne({
  subsets: ['latin'],
  variable: '--font-syne',
  weight: ['400', '600', '700', '800'],
})

const spaceMono = Space_Mono({
  subsets: ['latin'],
  variable: '--font-space-mono',
  weight: ['400', '700'],
})

const dmSans = DM_Sans({
  subsets: ['latin'],
  variable: '--font-dm-sans',
  weight: ['300', '400', '500'],
})

export const metadata: Metadata = {
  title: 'VERTX — Producer Dashboard',
  description: 'Upload and manage your cinematic series on VERTX.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${syne.variable} ${spaceMono.variable} ${dmSans.variable}`}>
      <body className="bg-black text-text font-sans antialiased">
        <AuthProvider>
          {children}
          <Toaster
            position="bottom-right"
            toastOptions={{
              style: {
                background: '#13131c',
                color: '#e8e8f0',
                border: '1px solid #1e1e2e',
                borderRadius: '0',
                fontFamily: 'var(--font-dm-sans)',
                fontSize: '0.875rem',
              },
              success: { iconTheme: { primary: '#e8ff47', secondary: '#060608' } },
              error:   { iconTheme: { primary: '#ff4757', secondary: '#060608' } },
            }}
          />
        </AuthProvider>
      </body>
    </html>
  )
}
