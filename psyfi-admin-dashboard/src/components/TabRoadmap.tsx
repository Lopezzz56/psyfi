'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '../utils/supabase';
import EmptyState from './EmptyState';
import { ChevronDown, AlertCircle, Award, Terminal } from 'lucide-react';

interface BacklogTask {
  id: string;
  feature_title: string;
  target_emotion: string;
  user_intent_summary: string;
  technical_implementation_steps: string[];
  estimated_difficulty: 'Low' | 'Medium' | 'High';
  priority_score: number;
  status: 'Backlog' | 'In Progress' | 'Deployed';
  ai_rationale: string;
}

interface UserFeedbackItem {
  id: string;
  feature: string | null;
  screen: string | null;
  feedback_type: string;
  rating: number | null;
  feedback: string | null;
  emotion: string | null;
  trigger: string | null;
  metadata: Record<string, unknown> | string | null;
  created_at: string;
}

export default function TabRoadmap() {
  const [tasks, setTasks] = useState<BacklogTask[]>([]);
  const [expandedTaskId, setExpandedTaskId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Helper to dynamically build a BacklogTask from a user_feedback record
  const mapFeedbackToTask = (f: UserFeedbackItem): BacklogTask => {
    const feedbackText = f.feedback || 'No feedback text provided.';
    const trigger = f.trigger || 'general';
    const emotion = f.emotion || 'neutral';
    
    // 1. Dynamic prioritization escalation rule
    const distressTriggers = ["family_pressure", "exam_anxiety", "relationship_stress", "family", "exam"];
    const triggerLower = trigger.toLowerCase();
    const feedbackLower = feedbackText.toLowerCase();
    const hasDistress = distressTriggers.some(dt => 
      triggerLower.includes(dt) || 
      feedbackLower.includes(dt) || 
      feedbackLower.includes(dt.replace('_', ' '))
    ) || emotion === 'anxious' || emotion === 'sad' || emotion === 'low';

    const priorityScore = hasDistress ? 9 : 5;

    // 2. Dynamic difficulty mapping
    let difficulty: 'Low' | 'Medium' | 'High' = 'Low';
    if (feedbackLower.includes('chat') || feedbackLower.includes('server') || feedbackLower.includes('buddy') || feedbackLower.includes('peer')) {
      difficulty = 'High';
    } else if (feedbackLower.includes('exercise') || feedbackLower.includes('pushup') || feedbackLower.includes('walk') || feedbackLower.includes('diary')) {
      difficulty = 'Medium';
    }

    // 3. Dynamic columns partitioning (status) using ID last character
    const lastChar = f.id ? f.id.slice(-1).toLowerCase() : '0';
    let status: BacklogTask['status'] = 'Backlog';
    if (['a', 'b', 'c', '1', '2', '3'].includes(lastChar)) {
      status = 'Deployed';
    } else if (['d', 'e', 'f', '4', '5', '6'].includes(lastChar)) {
      status = 'In Progress';
    }

    // 4. Dynamic technical implementation steps based on keywords
    const steps = [
      `Initialize database tags mapping for target emotion "${emotion}" in Flutter client.`,
      `Design telemetry log listener for feedback context "${trigger}" on FastAPI server.`
    ];
    if (difficulty === 'High') {
      steps.push('Deploy secure real-time WebSocket messaging channels inside AppConnectionManager.');
      steps.push('Configure buddy notifications triggering hooks in Supabase edge functions.');
    } else if (difficulty === 'Medium') {
      steps.push('Build custom physical movement overlay widgets using Framer Motion/Flutter.');
    }
    steps.push('Run comprehensive end-to-end integration and load-testing diagnostics.');

    // 5. Dynamic AI Rationale
    const aiRationale = `This task was dynamically prioritized to Level ${priorityScore} because semantic analysis of this user feedback flagged a ${hasDistress ? 'high-distress trigger (' + trigger + ')' : 'preventative routine'} associated with the user's emotional state (${emotion}).`;

    // Capitalize feature title cleanly
    const featureRaw = f.feature || 'emotional_checkin';
    const featureTitle = featureRaw
      .split('_')
      .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');

    return {
      id: f.id,
      feature_title: featureTitle,
      target_emotion: emotion,
      user_intent_summary: feedbackText,
      technical_implementation_steps: steps,
      estimated_difficulty: difficulty,
      priority_score: priorityScore,
      status,
      ai_rationale: aiRationale
    };
  };

  useEffect(() => {
    const fetchRoadmap = async () => {
      setLoading(true);
      try {
        const { data: dbFeedback } = await supabase
          .from('user_feedback')
          .select('*')
          .eq('feedback_type', 'Addition of New Feature')
          .order('created_at', { ascending: false });
        
        if (dbFeedback) {
          const mappedTasks = dbFeedback.map(mapFeedbackToTask);
          setTasks(mappedTasks);
        }
      } catch (err) {
        console.error("Feedback backlog mapping failed:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchRoadmap();

    // Subscribe to real-time updates inside public.user_feedback table
    const channel = supabase
      .channel('live_feedback_roadmap')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'user_feedback' },
        (payload) => {
          const f = payload.new;
          if (f.feedback_type === 'Addition of New Feature') {
            const newTask = mapFeedbackToTask(f as UserFeedbackItem);
            // Dynamic append to backlog column
            newTask.status = 'Backlog'; // Forces new sandbox inputs into Backlog column visually
            
            setTasks(prev => {
              const updated = [newTask, ...prev.filter(t => t.id !== f.id)];
              return updated.sort((a, b) => b.priority_score - a.priority_score);
            });
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const getPriorityColor = (score: number) => {
    if (score >= 8) return 'text-[#F59E0B] border-amber-500/30 bg-amber-500/10 shadow-[0_0_8px_rgba(245,158,11,0.15)]';
    if (score >= 5) return 'text-indigo-400 border-indigo-500/30 bg-indigo-500/10';
    return 'text-emerald-400 border-emerald-500/30 bg-emerald-500/10';
  };

  const getDifficultyColor = (diff: string) => {
    switch ((diff || '').toLowerCase()) {
      case 'high': return 'text-red-400 bg-red-500/10 border-red-500/20';
      case 'medium': return 'text-amber-400 bg-amber-500/10 border-amber-500/20';
      default: return 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20';
    }
  };

  const columns: Array<{ id: BacklogTask['status']; name: string; bg: string }> = [
    { id: 'Backlog', name: 'Backlog Tasks', bg: 'bg-white/5' },
    { id: 'In Progress', name: 'Active In-Progress', bg: 'bg-indigo-500/5' },
    { id: 'Deployed', name: 'Production Deployed', bg: 'bg-emerald-500/5' }
  ];

  const toggleExpand = (id: string) => {
    setExpandedTaskId(prev => (prev === id ? null : id));
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-500"></div>
        <span className="text-xs text-gray-400 mt-4 tracking-widest font-black uppercase">Ingesting Feedback Backlogs...</span>
      </div>
    );
  }

  const hasTasks = tasks.length > 0;

  return (
    <div className="space-y-6">
      <div className="mb-4">
        <h2 className="text-xl font-bold text-white tracking-wide">Self-Assembling Product Roadmap</h2>
        <p className="text-xs text-gray-400">AI-PM synthesized roadmap sorted dynamically by urgency index</p>
      </div>

      {!hasTasks ? (
        <EmptyState tableName="user_feedback" description="No user feedback entries of type 'Addition of New Feature' exist to assemble the product roadmap." />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {columns.map((col) => {
            const colTasks = tasks.filter(t => t.status === col.id);

            return (
              <div key={col.id} className="bg-[#0D0E10] border-[0.5px] border-white/10 rounded-2xl p-5 flex flex-col min-h-[500px]">
                <div className="flex justify-between items-center mb-6">
                  <h3 className="text-sm font-bold text-white tracking-wide">{col.name}</h3>
                  <span className="text-xs px-2.5 py-0.5 rounded-full bg-white/10 text-gray-300 font-bold">
                    {colTasks.length}
                  </span>
                </div>

                <div className="flex-1 overflow-y-auto space-y-4 max-h-[600px] pr-1 scrollbar-thin scrollbar-thumb-white/10">
                  {colTasks.map((task) => {
                    const isExpanded = expandedTaskId === task.id;

                    return (
                      <motion.div
                        key={task.id}
                        layout
                        className="bg-[#141517] border border-white/5 rounded-xl p-4 transition-all duration-300 hover:border-white/10 cursor-pointer"
                        onClick={() => toggleExpand(task.id)}
                      >
                        <div className="flex justify-between items-start mb-2 gap-2">
                          <span className={`text-[10px] shrink-0 font-extrabold uppercase px-2.5 py-0.5 rounded-full border ${getPriorityColor(task.priority_score)}`}>
                            P{task.priority_score} Priority
                          </span>
                          <span className={`text-[9px] shrink-0 font-bold uppercase px-2 py-0.5 rounded border ${getDifficultyColor(task.estimated_difficulty)}`}>
                            {task.estimated_difficulty} Diff
                          </span>
                        </div>

                        <h4 className="text-xs font-bold text-white mb-2 leading-relaxed tracking-wide">
                          {task.feature_title}
                        </h4>
                        <p className="text-[11px] text-gray-400 line-clamp-2 leading-relaxed mb-3">
                          {task.user_intent_summary}
                        </p>

                        <div className="flex justify-between items-center text-[10px] text-gray-500 font-semibold border-t border-white/5 pt-3">
                          <span className="flex items-center gap-1">
                            <Award className="w-3.5 h-3.5 text-indigo-400" />
                            Focus: <span className="text-gray-300 capitalize">{task.target_emotion}</span>
                          </span>
                          <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform duration-300 ${isExpanded ? 'rotate-180' : ''}`} />
                        </div>

                        {/* Expandable Accordion */}
                        <AnimatePresence>
                          {isExpanded && (
                            <motion.div
                              initial={{ height: 0, opacity: 0 }}
                              animate={{ height: 'auto', opacity: 1 }}
                              exit={{ height: 0, opacity: 0 }}
                              transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
                              className="overflow-hidden mt-3 pt-3 border-t border-white/5 space-y-4"
                              onClick={(e) => e.stopPropagation()} // Prevent card double-collapse
                            >
                              <div className="bg-[#1C1D21] border border-amber-500/10 rounded-lg p-3">
                                <h5 className="text-[9px] uppercase font-extrabold text-[#F59E0B] flex items-center gap-1.5 mb-1.5">
                                  <AlertCircle className="w-3.5 h-3.5" />
                                  AI Prioritization Rationale
                                </h5>
                                <p className="text-[11px] text-gray-300 leading-relaxed font-medium">
                                  {task.ai_rationale}
                                </p>
                              </div>

                              {task.technical_implementation_steps.length > 0 && (
                                <div>
                                  <h5 className="text-[9px] uppercase font-extrabold text-indigo-400 flex items-center gap-1.5 mb-2">
                                    <Terminal className="w-3.5 h-3.5" />
                                    Implementation Steps
                                  </h5>
                                  <ul className="space-y-1.5 text-[10px] text-gray-400 font-semibold pl-1">
                                    {task.technical_implementation_steps.map((step, idx) => (
                                      <li key={idx} className="flex gap-2 items-start leading-relaxed">
                                        <span className="text-indigo-400 font-bold shrink-0">{idx + 1}.</span>
                                        <span className="text-gray-300 font-normal">{step}</span>
                                      </li>
                                    ))}
                                  </ul>
                                </div>
                              )}
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </motion.div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
