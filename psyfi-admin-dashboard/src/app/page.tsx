'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import TabVitals from '../components/TabVitals';
import TabFriction from '../components/TabFriction';
import TabRoadmap from '../components/TabRoadmap';
import { Activity, ShieldAlert, Cpu, Heart, CheckCircle, RefreshCw } from 'lucide-react';

export default function Home() {
  const [activeTab, setActiveTab] = useState<'vitals' | 'friction' | 'roadmap'>('vitals');
  const [feedbackInput, setFeedbackInput] = useState('');
  const [feedbackType, setFeedbackType] = useState('Addition of New Feature');
  const [emotionInput, setEmotionInput] = useState('anxious');
  const [triggerInput, setTriggerInput] = useState('family_pressure');
  const [loading, setLoading] = useState(false);
  const [successTask, setSuccessTask] = useState<Record<string, string | number | string[]> | null>(null);
  const [errorText, setErrorText] = useState('');

  const tabs: Array<{ id: typeof activeTab; label: string; icon: React.ComponentType<{ className?: string }> }> = [
    { id: 'vitals', label: 'System Vitals', icon: Activity },
    { id: 'friction', label: 'Friction Matrix', icon: ShieldAlert },
    { id: 'roadmap', label: 'AI Product Roadmap', icon: Cpu },
  ];

  const handleTriggerAIPM = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!feedbackInput.trim()) return;

    setLoading(true);
    setSuccessTask(null);
    setErrorText('');

    try {
      const response = await fetch('/api/process-feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          feedback: feedbackInput,
          emotion: emotionInput,
          trigger: triggerInput,
        }),
      });

      const result = await response.json();
      if (!response.ok) {
        throw new Error(result.error || 'Server error');
      }

      setSuccessTask(result.task);
      setFeedbackInput('');
    } catch (err: unknown) {
      setErrorText((err as Error).message || 'Connection failed. Please verify GEMINI_API_KEY in .env.local');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-[#000000] text-gray-100 flex flex-col relative">
      {/* Decorative ambient shadows */}
      <div className="absolute top-[-10%] left-[20%] w-[500px] h-[500px] bg-indigo-900/10 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[10%] w-[500px] h-[500px] bg-emerald-950/10 rounded-full blur-[120px] pointer-events-none" />

      {/* Main Container */}
      <div className="max-w-7xl mx-auto w-full px-6 py-8 flex-1 flex flex-col gap-8 relative z-10">
        
        {/* Header Bar */}
        <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-white/5 pb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#6366F1] to-[#10B981] flex items-center justify-center shadow-[0_0_20px_rgba(99,102,241,0.3)]">
              <Heart className="w-5.5 h-5.5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-black text-white tracking-widest uppercase">
                PsyFi <span className="text-[#10B981]">Executive</span>
              </h1>
              <p className="text-[10px] text-gray-500 uppercase tracking-widest font-extrabold">
                Intelligent Product Analytics Hub
              </p>
            </div>
          </div>

          {/* Tab Controls with liquid slider */}
          <div className="flex bg-[#0D0E10] border-[0.5px] border-white/10 rounded-xl p-1 relative">
            {tabs.map((tab) => {
              const TabIcon = tab.icon;
              const isActive = activeTab === tab.id;

              return (
                <button
                  key={tab.id}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setSuccessTask(null);
                  }}
                  className={`flex items-center gap-2 px-4 py-2 text-xs font-bold uppercase tracking-wider relative transition-colors duration-300 z-10 ${
                    isActive ? 'text-white font-extrabold' : 'text-gray-400 hover:text-white'
                  }`}
                >
                  <TabIcon className="w-4 h-4" />
                  {tab.label}

                  {isActive && (
                    <motion.div
                      layoutId="activeTabIndicator"
                      className="absolute inset-0 bg-white/5 border border-white/10 rounded-lg shadow-[0_0_15px_rgba(255,255,255,0.03)] z-[-1]"
                      transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                    />
                  )}
                </button>
              );
            })}
          </div>
        </header>

        {/* Global Statistics Banner */}
        <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-xl p-4 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center shrink-0">
              <Activity className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <span className="text-[9px] uppercase font-bold text-gray-500 block">Overall Vitals</span>
              <span className="text-sm font-extrabold text-white">94.8% Stable</span>
            </div>
          </div>

          <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-xl p-4 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center shrink-0">
              <Cpu className="w-5 h-5 text-indigo-400" />
            </div>
            <div>
              <span className="text-[9px] uppercase font-bold text-gray-500 block">Active Users</span>
              <span className="text-sm font-extrabold text-white">12,450 / Live</span>
            </div>
          </div>

          <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-xl p-4 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-[#F59E0B]/10 border border-[#F59E0B]/20 flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5 text-[#F59E0B]" />
            </div>
            <div>
              <span className="text-[9px] uppercase font-bold text-gray-500 block">Friction Indices</span>
              <span className="text-sm font-extrabold text-white">2 Alerts Triggered</span>
            </div>
          </div>

          <div className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-xl p-4 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-purple-500/10 border border-purple-500/20 flex items-center justify-center shrink-0">
              <CheckCircle className="w-5 h-5 text-purple-400" />
            </div>
            <div>
              <span className="text-[9px] uppercase font-bold text-gray-500 block">AI Self-Healing Loops</span>
              <span className="text-sm font-extrabold text-white">49 Backlogs Generated</span>
            </div>
          </div>
        </section>

        {/* Tab Contents */}
        <div className="flex-1 flex flex-col min-h-0">
          {activeTab === 'vitals' && <TabVitals />}
          {activeTab === 'friction' && <TabFriction />}
          {activeTab === 'roadmap' && <TabRoadmap />}
        </div>

        {/* Interactive AI PM loop trigger Sandbox Console */}
        <section className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-2xl p-6 relative overflow-hidden backdrop-blur-md">
          <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/5 rounded-full blur-3xl pointer-events-none" />
          
          <div className="mb-4">
            <h2 className="text-md font-bold text-white tracking-wide flex items-center gap-2">
              <Cpu className="w-5 h-5 text-indigo-400" />
              AI PM Self-Healing Sandbox Console
            </h2>
            <p className="text-xs text-gray-400">Directly ingest unstructured feedback to trigger the Gemini Structured prioritized backlog pipeline</p>
          </div>

          <form onSubmit={handleTriggerAIPM} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="text-[10px] uppercase font-extrabold text-gray-400 block mb-1">Feedback Type</label>
                <select 
                  value={feedbackType} 
                  onChange={(e) => setFeedbackType(e.target.value)}
                  className="w-full bg-[#141517] border border-white/10 rounded-xl px-3 py-2 text-xs font-semibold text-white focus:outline-none focus:border-indigo-500"
                >
                  <option value="Addition of New Feature">Addition of New Feature</option>
                  <option value="Bug Report">Bug Report</option>
                  <option value="UI Feedback">UI Feedback</option>
                </select>
              </div>

              <div>
                <label className="text-[10px] uppercase font-extrabold text-gray-400 block mb-1">Inferred Emotion</label>
                <select 
                  value={emotionInput} 
                  onChange={(e) => setEmotionInput(e.target.value)}
                  className="w-full bg-[#141517] border border-white/10 rounded-xl px-3 py-2 text-xs font-semibold text-white focus:outline-none focus:border-indigo-500"
                >
                  <option value="anxious">Anxious</option>
                  <option value="sad">Sad / Low</option>
                  <option value="calm">Calm / Healing</option>
                  <option value="neutral">Neutral</option>
                </select>
              </div>

              <div>
                <label className="text-[10px] uppercase font-extrabold text-gray-400 block mb-1">Feedback Context Trigger</label>
                <select 
                  value={triggerInput} 
                  onChange={(e) => setTriggerInput(e.target.value)}
                  className="w-full bg-[#141517] border border-white/10 rounded-xl px-3 py-2 text-xs font-semibold text-white focus:outline-none focus:border-indigo-500"
                >
                  <option value="family_pressure">Family Pressure (Distress Escalation)</option>
                  <option value="exam_anxiety">Exam Anxiety (Distress Escalation)</option>
                  <option value="relationship_stress">Relationship Stress (Distress Escalation)</option>
                  <option value="daily_checkin">General Daily Check-In</option>
                </select>
              </div>
            </div>

            <div>
              <label className="text-[10px] uppercase font-extrabold text-gray-400 block mb-1">Unstructured Text Feedback</label>
              <textarea
                value={feedbackInput}
                onChange={(e) => setFeedbackInput(e.target.value)}
                placeholder="e.g. 'I want somatic pushups and walking exercises because exam_anxiety is making my chest incredibly heavy.'"
                className="w-full bg-[#141517] border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-indigo-500 h-20 resize-none"
              />
            </div>

            <div className="flex justify-between items-center gap-4">
              <button
                type="submit"
                disabled={loading || !feedbackInput.trim()}
                className="bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 disabled:opacity-50 text-white font-extrabold text-xs uppercase tracking-widest px-6 py-2.5 rounded-xl transition-all duration-300 flex items-center gap-2 shadow-[0_0_20px_rgba(99,102,241,0.25)] hover:shadow-[0_0_20px_rgba(99,102,241,0.4)]"
              >
                {loading ? (
                  <RefreshCw className="w-4 h-4 animate-spin" />
                ) : (
                  <Cpu className="w-4 h-4" />
                )}
                Trigger self-healing loop
              </button>

              {errorText && (
                <span className="text-xs text-amber-500 font-bold leading-relaxed pr-2">
                  {errorText}
                </span>
              )}
            </div>
          </form>

          {/* Success Response visual feedback overlay */}
          {successTask && (
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-6 p-4 bg-[#141517] border border-emerald-500/20 rounded-xl"
            >
              <h3 className="text-xs font-black text-emerald-400 uppercase tracking-widest flex items-center gap-2 mb-2">
                <CheckCircle className="w-4.5 h-4.5" />
                Task structured and stored successfully inside public.ai_product_backlog!
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div>
                  <p className="text-gray-400 font-semibold mb-1">Feature: <span className="text-white font-bold">{successTask.feature_title}</span></p>
                  <p className="text-gray-400 font-semibold mb-1">Target Emotion: <span className="text-indigo-400 font-bold capitalize">{successTask.target_emotion}</span></p>
                  <p className="text-gray-400 font-semibold">Priority: <span className="text-amber-500 font-extrabold">Level {successTask.priority_score}/10</span></p>
                </div>
                <div>
                  <p className="text-gray-400 font-semibold mb-1">Intent Summary:</p>
                  <p className="text-gray-300 font-medium">{successTask.user_intent_summary}</p>
                </div>
              </div>
            </motion.div>
          )}
        </section>

      </div>
    </main>
  );
}
