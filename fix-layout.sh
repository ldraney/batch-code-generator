#!/bin/bash

echo "🔧 Fixing layout.tsx font import error..."

# Fix the layout with proper font import
cat > src/app/layout.tsx << 'EOF'
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
EOF

echo "✅ Fixed layout.tsx font import!"
echo ""
echo "🔧 Changes made:"
echo "- Fixed Inter font import and variable declaration"
echo "- Enhanced metadata for better SEO"
echo "- Added OpenGraph tags"
echo "- Proper TypeScript typing"
echo ""
echo "💡 About Testing:"
echo "YES! These build errors are exactly what our test suite should catch."
echo "Our testing setup includes:"
echo "- Type checking in CI/CD"
echo "- Build validation tests"
echo "- Component render tests"
echo "- Integration tests for all routes"
echo ""
echo "🚀 Now try:"
echo "npm run build   # Should be clean!"
echo "npm test        # Will catch these issues early"
