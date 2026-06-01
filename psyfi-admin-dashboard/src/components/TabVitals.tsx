'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Area, XAxis, YAxis, Tooltip, ResponsiveContainer, ComposedChart
} from 'recharts';
import { supabase } from '../utils/supabase';
import EmptyState from './EmptyState';

interface DailySnapshot {
  id: string;
  avg_severity: number;
  intervention_success_rate: number;
  created_at: string;
}

interface EmotionalSignal {
  id: string;
  user_id: string;
  emotion: string;
  trigger: string;
  severity: string;
  care_state: string;
  intervention_used: string | null;
  effectiveness_score: number | null;
  local_created_at: string;
  uploaded_at: string;
}

export default function TabVitals() {
  const [snapshots, setSnapshots] = useState<DailySnapshot[]>([]);
  const [signals, setSignals] = useState<EmotionalSignal[]>([]);
  const [funnelData, setFunnelData] = useState({ signals: 0, clicked: 0, completed: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchVitals = async () => {
      setLoading(true);
      try {
        // 1. Fetch chronological daily snapshots
        const { data: dbSnapshots } = await supabase
          .from('daily_emotional_snapshots')
          .select('id, avg_severity, intervention_success_rate, created_at')
          .order('created_at', { ascending: true })
          .limit(30);
        
        if (dbSnapshots) {
          // Map to force numbers
          const formattedSnaps = dbSnapshots.map(snap => ({
            id: snap.id,
            avg_severity: Number(snap.avg_severity) || 0,
            intervention_success_rate: Number(snap.intervention_success_rate) || 0,
            created_at: snap.created_at
          }));
          setSnapshots(formattedSnaps);
        }

        // 2. Fetch raw emotional signals for cascade
        const { data: dbSignals } = await supabase
          .from('emotional_signals')
          .select('id, user_id, emotion, trigger, severity, care_state, intervention_used, effectiveness_score, local_created_at, uploaded_at')
          .order('uploaded_at', { ascending: false })
          .limit(10);
        
        if (dbSignals) {
          setSignals(dbSignals);
        }

        // 3. Compute funnel analytics by counting rows
        const { count: totalSignals } = await supabase
          .from('emotional_signals')
          .select('*', { count: 'exact', head: true });

        const { count: clickedCount } = await supabase
          .from('intervention_analytics')
          .select('*', { count: 'exact', head: true })
          .eq('clicked', true);

        const { count: completedCount } = await supabase
          .from('intervention_analytics')
          .select('*', { count: 'exact', head: true })
          .eq('completed', true);

        setFunnelData({
          signals: totalSignals || 0,
          clicked: clickedCount || 0,
          completed: completedCount || 0
        });

      } catch (err) {
        console.error("Vitals query failed:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchVitals();

    // 4. Setup postgres real-time listener to append new signals instantly
    const channel = supabase
      .channel('realtime_signals')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'emotional_signals' },
        (payload) => {
          const newSig = payload.new as EmotionalSignal;
          setSignals(prev => [newSig, ...prev.slice(0, 8)]);
          setFunnelData(prev => ({
            ...prev,
            signals: prev.signals + 1
          }));
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const getEmotionColor = (emotion: string) => {
    switch ((emotion || '').toLowerCase()) {
      case 'anxious': return 'from-[#F59E0B] to-[#D97706]';
      case 'sad': return 'from-[#6366F1] to-[#4F46E5]';
      case 'calm':
      case 'healing': 
        return 'from-[#10B981] to-[#059669]';
      default: return 'from-[#9CA3AF] to-[#6B7280]';
    }
  };

  const getEmotionGlow = (emotion: string) => {
    switch ((emotion || '').toLowerCase()) {
      case 'anxious': return 'shadow-[0_0_15px_rgba(245,158,11,0.25)] border-[#F59E0B]/25 bg-[#F59E0B]/5';
      case 'sad': return 'shadow-[0_0_15px_rgba(99,102,241,0.25)] border-[#6366F1]/25 bg-[#6366F1]/5';
      case 'calm':
      case 'healing':
        return 'shadow-[0_0_15px_rgba(16,185,129,0.25)] border-[#10B981]/25 bg-[#10B981]/5';
      default: return 'shadow-none border-white/5';
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-500"></div>
        <span className="text-xs text-gray-400 mt-4 tracking-widest font-black uppercase">Loading Database Logs...</span>
      </div>
    );
  }

  const hasChartData = snapshots.length > 0;
  const hasSignalsData = signals.length > 0;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Chart Section */}
      <div className="lg:col-span-2 space-y-6">
        <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-2xl p-6 relative overflow-hidden backdrop-blur-md">
          <div className="absolute top-0 left-0 w-32 h-32 bg-[#6366F1]/10 rounded-full blur-3xl pointer-events-none" />
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-lg font-bold text-white tracking-wide">Macro Wellness Vitals</h2>
              <p className="text-xs text-gray-400">Emotional Severity vs. Intervention Success Rates</p>
            </div>
            {hasChartData && (
              <div className="flex gap-4 text-xs font-bold">
                <span className="flex items-center gap-1.5 text-[#F59E0B]">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#F59E0B] inline-block shadow-[0_0_8px_#F59E0B]" />
                  Severity (1-10)
                </span>
                <span className="flex items-center gap-1.5 text-[#10B981]">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#10B981] inline-block shadow-[0_0_8px_#10B981]" />
                  Success Rate (%)
                </span>
              </div>
            )}
          </div>

          {!hasChartData ? (
            <EmptyState tableName="daily_emotional_snapshots" description="No macro daily emotional snapshots have been aggregated from the client application yet." />
          ) : (
            <div className="h-72 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={snapshots} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorSeverity" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.25}/>
                      <stop offset="95%" stopColor="#F59E0B" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorSuccess" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10B981" stopOpacity={0.25}/>
                      <stop offset="95%" stopColor="#10B981" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <XAxis 
                    dataKey="created_at" 
                    tickFormatter={(str) => {
                      const d = new Date(str);
                      return isNaN(d.getTime()) ? '' : d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
                    }}
                    stroke="#4B5563"
                    fontSize={10}
                    tickLine={false}
                  />
                  <YAxis yAxisId="left" stroke="#4B5563" fontSize={10} tickLine={false} domain={[0, 10]} />
                  <YAxis yAxisId="right" orientation="right" stroke="#4B5563" fontSize={10} tickLine={false} domain={[0, 100]} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#0D0E10', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '12px' }}
                    labelStyle={{ color: '#fff', fontWeight: 'bold', fontSize: '11px' }}
                    itemStyle={{ fontSize: '12px' }}
                  />
                  <Area yAxisId="left" type="monotone" dataKey="avg_severity" stroke="#F59E0B" strokeWidth={2} fillOpacity={1} fill="url(#colorSeverity)" name="Emotional Severity" />
                  <Area yAxisId="right" type="monotone" dataKey="intervention_success_rate" stroke="#10B981" strokeWidth={2} fillOpacity={1} fill="url(#colorSuccess)" name="Success Rate %" />
                </ComposedChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>

        {/* Funnel Widget */}
        <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-2xl p-6 relative overflow-hidden backdrop-blur-md">
          <h2 className="text-lg font-bold text-white mb-1 tracking-wide">Intervention Conversion Funnel</h2>
          <p className="text-xs text-gray-400 mb-6">User journeys through active coping steps</p>

          {funnelData.signals === 0 ? (
            <EmptyState tableName="intervention_analytics" description="No signals or intervention engagement telemetry logs have been detected in Supabase." />
          ) : (
            <div className="space-y-4">
              {/* Level 1: Triggered */}
              <div>
                <div className="flex justify-between text-xs font-bold text-gray-300 mb-1.5">
                  <span>Triggered Signals</span>
                  <span className="text-white">{funnelData.signals}</span>
                </div>
                <div className="w-full bg-[#1A1C20] h-3.5 rounded-full overflow-hidden border border-white/5">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: '100%' }}
                    transition={{ duration: 1.5, ease: 'easeOut' }}
                    className="bg-gradient-to-r from-indigo-500 to-purple-600 h-full rounded-full shadow-[0_0_12px_rgba(99,102,241,0.5)]"
                  />
                </div>
              </div>

              {/* Level 2: Clicked */}
              <div>
                <div className="flex justify-between text-xs font-bold text-gray-300 mb-1.5">
                  <span>Interventions Engaged</span>
                  <span className="text-white">
                    {funnelData.clicked}{' '}
                    <span className="text-gray-500 font-normal">
                      ({funnelData.signals > 0 ? Math.round((funnelData.clicked / funnelData.signals) * 100) : 0}%)
                    </span>
                  </span>
                </div>
                <div className="w-full bg-[#1A1C20] h-3.5 rounded-full overflow-hidden border border-white/5">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: `${funnelData.signals > 0 ? (funnelData.clicked / funnelData.signals) * 100 : 0}%` }}
                    transition={{ duration: 1.5, ease: 'easeOut', delay: 0.2 }}
                    className="bg-gradient-to-r from-[#F59E0B] to-[#D97706] h-full rounded-full shadow-[0_0_12px_rgba(245,158,11,0.5)]"
                  />
                </div>
              </div>

              {/* Level 3: Completed */}
              <div>
                <div className="flex justify-between text-xs font-bold text-gray-300 mb-1.5">
                  <span>Interventions Completed</span>
                  <span className="text-white">
                    {funnelData.completed}{' '}
                    <span className="text-gray-500 font-normal">
                      ({funnelData.clicked > 0 ? Math.round((funnelData.completed / funnelData.clicked) * 100) : 0}% Conversion)
                    </span>
                  </span>
                </div>
                <div className="w-full bg-[#1A1C20] h-3.5 rounded-full overflow-hidden border border-white/5">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: `${funnelData.signals > 0 ? (funnelData.completed / funnelData.signals) * 100 : 0}%` }}
                    transition={{ duration: 1.5, ease: 'easeOut', delay: 0.4 }}
                    className="bg-gradient-to-r from-[#10B981] to-[#059669] h-full rounded-full shadow-[0_0_12px_rgba(16,185,129,0.5)]"
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Real-time signals list */}
      <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-2xl p-6 flex flex-col h-[535px] relative overflow-hidden backdrop-blur-md">
        <div className="absolute top-0 right-0 w-32 h-32 bg-[#10B981]/5 rounded-full blur-3xl pointer-events-none" />
        <div className="mb-4">
          <div className="flex items-center gap-2">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-red-500"></span>
            </span>
            <h2 className="text-md font-bold text-white tracking-wide">Live Signal Cascade</h2>
          </div>
          <p className="text-xs text-gray-400">Database signals flowing in real-time</p>
        </div>

        {!hasSignalsData ? (
          <EmptyState tableName="emotional_signals" description="No client-side emotional signals are currently cascading in the live Supabase stream." />
        ) : (
          <div className="flex-1 overflow-y-auto space-y-3.5 scrollbar-thin scrollbar-thumb-white/10 pr-1">
            <AnimatePresence initial={false}>
              {signals.map((sig) => (
                <motion.div
                  key={sig.id}
                  initial={{ opacity: 0, y: -40, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                  className={`bg-[#141517] border-[0.5px] rounded-xl p-3.5 flex items-center justify-between transition-all duration-300 backdrop-blur-md ${getEmotionGlow(sig.emotion)}`}
                >
                  <div className="space-y-1 pr-2">
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] uppercase font-extrabold px-2 py-0.5 rounded-full text-white bg-gradient-to-r ${getEmotionColor(sig.emotion)}`}>
                        {sig.emotion}
                      </span>
                      <span className="text-[10px] text-gray-500">
                        {new Date(sig.uploaded_at || sig.local_created_at).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                      </span>
                    </div>
                    <p className="text-xs font-semibold text-white tracking-wide">
                      Trigger: <span className="text-gray-300 font-normal">{(sig.trigger || '').replace('_', ' ')}</span>
                    </p>
                    <p className="text-[10px] text-gray-400">
                      Care State: <span className="text-white font-medium capitalize">{sig.care_state}</span>
                    </p>
                  </div>
                  {sig.intervention_used && (
                    <div className="text-right flex flex-col items-end shrink-0">
                      <span className="text-[9px] uppercase font-extrabold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                        {sig.intervention_used}
                      </span>
                      {sig.effectiveness_score && (
                        <span className="text-[9px] text-gray-400 mt-1">
                          Score: <span className="text-white font-bold">{sig.effectiveness_score}/10</span>
                        </span>
                      )}
                    </div>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  );
}
