import { Inter } from 'next/font/google';
import './globals.css';
import * as Sentry from '@sentry/nextjs';
import type { Metadata } from 'next';

// Add or edit your "generateMetadata" to include the Sentry trace data:
export function generateMetadata(): Metadata {
  return {
    // ... your existing metadata
    other: {
      ...Sentry.getTraceData()
    }
  };
}

// const inter = Inter({ subsets: ['latin'] });
//
// export const metadata: Metadata = {
//   title: 'Batch Code Generator',
//   description: 'Generate code in batches via webhook',
// };

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}

