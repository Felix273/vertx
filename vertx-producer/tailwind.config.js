/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // VERTX design system
        black:    '#060608',
        surface:  '#0e0e14',
        card:     '#13131c',
        border:   '#1e1e2e',
        accent:   '#e8ff47',
        accent2:  '#ff4757',
        accent3:  '#7c6aff',
        green:    '#2dff8a',
        muted:    '#6b6b80',
        text:     '#e8e8f0',
      },
      fontFamily: {
        syne:  ['var(--font-syne)', 'sans-serif'],
        mono:  ['var(--font-space-mono)', 'monospace'],
        sans:  ['var(--font-dm-sans)', 'sans-serif'],
      },
      borderRadius: {
        none: '0',
      },
      animation: {
        'fade-in':    'fadeIn 0.3s ease',
        'slide-up':   'slideUp 0.3s ease',
        'pulse-slow': 'pulse 3s ease-in-out infinite',
      },
      keyframes: {
        fadeIn:  { from: { opacity: '0', transform: 'translateY(6px)' }, to: { opacity: '1', transform: 'translateY(0)' } },
        slideUp: { from: { opacity: '0', transform: 'translateY(16px)' }, to: { opacity: '1', transform: 'translateY(0)' } },
      },
    },
  },
  plugins: [],
}
