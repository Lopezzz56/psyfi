'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Database, RefreshCw } from 'lucide-react';

interface EmptyStateProps {
  tableName: string;
  description?: string;
}

export default function EmptyState({ tableName, description }: EmptyStateProps) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className="flex flex-col items-center justify-center border-[0.5px] border-white/10 bg-[#0D0E10] rounded-2xl p-10 text-center min-h-[300px] w-full relative overflow-hidden backdrop-blur-md"
    >
      <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-500/5 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none" />

      {/* Pulsing Sync Ring */}
      <div className="relative flex h-14 w-14 items-center justify-center mb-6">
        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-500/10 opacity-75"></span>
        <div className="relative rounded-2xl bg-indigo-500/10 border border-indigo-500/30 w-12 h-12 flex items-center justify-center shadow-[0_0_15px_rgba(99,102,241,0.2)]">
          <Database className="w-6 h-6 text-indigo-400" />
        </div>
      </div>

      <h3 className="text-md font-extrabold text-white tracking-wider mb-2">
        AWAITING TELEMETRY STREAM
      </h3>
      
      <p className="text-xs text-gray-400 max-w-sm leading-relaxed mb-4">
        {description || `No live data has been recorded in the Supabase "${tableName}" database table yet.`}
      </p>

      <div className="bg-[#141517] border border-white/5 rounded-xl p-3.5 mb-6 max-w-md text-left">
        <h4 className="text-[10px] uppercase font-extrabold text-amber-400 mb-1.5 flex items-center gap-1.5">
          💡 RLS / Policy Check
        </h4>
        <p className="text-[10px] text-gray-400 leading-relaxed font-semibold">
          If this table is already populated in your Supabase dashboard, **Row Level Security (RLS)** is blocking anonymous client select requests. Run this SQL in your Supabase editor to allow data retrieval:
        </p>
        <code className="block bg-black/50 border border-white/10 rounded px-2 py-1 text-[9px] text-[#10B981] font-mono mt-2 select-all">
          alter table public.{tableName} disable row level security;
        </code>
      </div>

      <div className="flex items-center gap-2 text-[10px] text-gray-500 uppercase tracking-widest font-black bg-white/5 border border-white/5 px-3 py-1.5 rounded-full">
        <RefreshCw className="w-3.5 h-3.5 animate-spin text-indigo-400" />
        Synchronizing Live Logs
      </div>
    </motion.div>
  );
}
