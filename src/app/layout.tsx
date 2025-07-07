import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Batch Code Generator',
  description: 'Generate code in batches via webhook with comprehensive monitoring',
  keywords: ['code generation', 'webhooks', 'monitoring', 'batch processing'],
  authors: [{ name: 'Your Name' }],
  openGraph: {
    title: 'Batch Code Generator',
    description: 'Generate code in batches via webhook with comprehensive monitoring',
    type: 'website',
  },
};

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
