'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '../utils/supabase';
import EmptyState from './EmptyState';
import { Percent, BarChart2 } from 'lucide-react';

interface FeatureFrictionItem {
  feature: string;
  usage_count: number;
  quick_negative: number;
  positive: number;
  friction_ratio: number;
  details: string;
}

export default function TabFriction() {
  const [gridData, setGridData] = useState<FeatureFrictionItem[]>([]);
  const [hoveredId, setHoveredId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchFriction = async () => {
      setLoading(true);
      try {
        const { data: feedbackData } = await supabase
          .from('user_feedback')
          .select('feature, feedback_type, rating');
        
        if (feedbackData && feedbackData.length > 0) {
          // Extract unique features dynamically from the database
          const uniqueFeatures = Array.from(new Set(feedbackData.map(f => f.feature).filter(Boolean)));
          
          const processed: FeatureFrictionItem[] = uniqueFeatures.map(featureName => {
            const matches = feedbackData.filter(f => f.feature === featureName);
            const negatives = matches.filter(f => f.feedback_type === 'quick_negative').length;
            const positives = matches.length - negatives;
            const ratio = matches.length > 0 
              ? parseFloat(((negatives / matches.length) * 100).toFixed(1)) 
              : 0;

            let details = `Interactive analytics for the "${featureName}" feature module.`;
            if (featureName === 'suggested_for_you') details = 'Recommended custom interventions feed screen.';
            else if (featureName === 'aichat') details = 'Empathetic chatbot companion assistant conversations.';
            else if (featureName === 'daily_motivation') details = 'Daily motivational quotes and emotional seed items.';
            else if (featureName === 'diary_reflection') details = 'First-person weekly cognitive memory diary summaries.';
            else if (featureName === 'somatic_exercises') details = 'Physical grounding sequences, pushups, and walks.';

            return {
              feature: featureName as string,
              usage_count: matches.length,
              quick_negative: negatives,
              positive: positives,
              friction_ratio: ratio,
              details
            };
          });

          // Sort features by total usage count descending
          processed.sort((a, b) => b.usage_count - a.usage_count);
          setGridData(processed);
        } else {
          setGridData([]);
        }
      } catch (err) {
        console.error("Feedback query failed:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchFriction();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-500"></div>
        <span className="text-xs text-gray-400 mt-4 tracking-widest font-black uppercase">Analyzing Feedback Volatility...</span>
      </div>
    );
  }

  const hasData = gridData.length > 0;

  return (
    <div className="space-y-6">
      <div className="mb-4">
        <h2 className="text-xl font-bold text-white tracking-wide">Feature Friction & Volatility Matrix</h2>
        <p className="text-xs text-gray-400">Comparing positive interactions against raw friction indices (quick_negative logs)</p>
      </div>

      {!hasData ? (
        <EmptyState tableName="user_feedback" description="No client-side feature usage or feedback events have been logged in Supabase yet." />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {gridData.map((item) => {
            const isHighFriction = item.friction_ratio >= 15;
            const isHovered = hoveredId === item.feature;

            return (
              <motion.div
                key={item.feature}
                onMouseEnter={() => setHoveredId(item.feature)}
                onMouseLeave={() => setHoveredId(null)}
                layout
                className={`bg-[#0D0E10] border-[0.5px] rounded-2xl p-5 relative overflow-hidden backdrop-blur-md cursor-pointer transition-all duration-300 ${
                  isHighFriction 
                    ? 'border-amber-500/20 hover:border-amber-500/50 shadow-[0_0_20px_rgba(245,158,11,0.03)]' 
                    : 'border-white/10 hover:border-[#10B981]/40'
                }`}
              >
                {/* Background gradient */}
                <div className={`absolute top-0 right-0 w-24 h-24 rounded-full blur-3xl pointer-events-none ${
                  isHighFriction ? 'bg-amber-500/5' : 'bg-emerald-500/5'
                }`} />

                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-sm font-extrabold text-white tracking-wider uppercase">{(item.feature || '').replace('_', ' ')}</h3>
                    <p className="text-[11px] text-gray-400 mt-0.5">{item.details}</p>
                  </div>

                  {isHighFriction ? (
                    <div className="relative flex h-3 w-3 shrink-0">
                      <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
                      <span className="relative inline-flex rounded-full h-3 w-3 bg-amber-500 shadow-[0_0_12px_#F59E0B]"></span>
                    </div>
                  ) : (
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0 shadow-[0_0_8px_#10B981]" />
                  )}
                </div>

                {/* Stats telemetry */}
                <div className="grid grid-cols-2 gap-4 mt-6">
                  <div className="bg-[#141517] border border-white/5 rounded-xl p-3 text-center">
                    <span className="text-[9px] uppercase font-bold text-gray-500 block">Total Logs</span>
                    <span className="text-sm font-extrabold text-white">{item.usage_count}</span>
                  </div>
                  <div className="bg-[#141517] border border-white/5 rounded-xl p-3 text-center">
                    <span className="text-[9px] uppercase font-bold text-gray-500 block">Friction Ratio</span>
                    <span className={`text-sm font-extrabold flex items-center justify-center gap-0.5 ${
                      isHighFriction ? 'text-amber-500' : 'text-emerald-400'
                    }`}>
                      {item.friction_ratio}%
                      <Percent className="w-3 h-3" />
                    </span>
                  </div>
                </div>

                {/* Framer motion expansion telemetry on hover */}
                <AnimatePresence>
                  {isHovered && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                      className="overflow-hidden mt-4 pt-4 border-t border-white/5"
                    >
                      <h4 className="text-[10px] uppercase font-extrabold text-gray-400 mb-2.5 flex items-center gap-1.5">
                        <BarChart2 className="w-3.5 h-3.5 text-indigo-400" />
                        Diagnostic Telemetry
                      </h4>
                      <div className="space-y-1.5 text-[11px] text-gray-300">
                        <div className="flex justify-between">
                          <span>quick_negative logs:</span>
                          <span className="text-red-400 font-bold">{item.quick_negative}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Successful logs:</span>
                          <span className="text-emerald-400 font-bold">{item.positive}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Care State Context:</span>
                          <span className="text-white font-bold capitalize">
                            {isHighFriction ? 'High Distress Trigger' : 'Optimized Healing'}
                          </span>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>
      )}
    </div>
  );
}
