import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'PsyFi Executive - Intelligent Analytics & AIPM Dashboard',
  description: 'Production-ready premium telemetry analytics console mapping emotional snapshots, feature volatility, and self-assembling roadmap backlogs.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
