import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://yakwebqtwodfdpgvmanx.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export async function POST(req: Request) {
  try {
    const { feedback, emotion, trigger } = await req.json();
    
    if (!feedback) {
      return NextResponse.json({ error: 'Feedback text is required' }, { status: 400 });
    }

    const geminiKey = process.env.GEMINI_API_KEY;
    if (!geminiKey) {
      return NextResponse.json({ error: 'GEMINI_API_KEY is not configured in .env.local' }, { status: 500 });
    }

    // 1. Setup Gemini prompt with dynamic escalation criteria
    const prompt = `
Analyze the following user feedback requesting a new feature for the mental wellness application "PsyFi".
Extract the core suggestion and structure it exactly matching this JSON schema:

{
  "feature_title": "Short descriptive title of the requested feature",
  "target_emotion": "The primary emotion this feature aims to support",
  "user_intent_summary": "Concise summary of what the user wants to achieve and why",
  "technical_implementation_steps": [
    "Step 1 to implement this in Flutter/FastAPI",
    "Step 2...",
    "Step 3..."
  ],
  "estimated_difficulty": "Low" or "Medium" or "High",
  "priority_score": 1 to 10 integer
}

Rules:
1. "priority_score" must be an integer between 1 and 10.
2. CRITICAL PRIORITIZATION ESCALATION RULE: If the feedback context reveals high-distress triggers such as "family_pressure", "exam_anxiety", or "relationship_stress", combined with a severe emotional state, you MUST escalate and set the "priority_score" to Level 8, 9, or 10.
3. Keep technical steps practical for a Flutter + FastAPI stack.

User Feedback: "${feedback}"
User Inferred Emotion: "${emotion || 'neutral'}"
User Trigger: "${trigger || 'general'}"

Return ONLY the raw JSON string matching the schema. No markdown formatting, no code blocks (like \`\`\`json).
`;

    // 2. Call high-speed Gemini REST Endpoint
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' }
        })
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      return NextResponse.json({ error: `Gemini API error: ${errText}` }, { status: 502 });
    }

    const resJson = await response.json();
    const rawText = resJson?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
    
    // 3. Parse JSON and double check priority score
    const task = JSON.parse(rawText.trim());

    const distressTriggers = ["family_pressure", "exam_anxiety", "relationship_stress"];
    const triggerLower = (trigger || '').toLowerCase();
    const feedbackLower = feedback.toLowerCase();
    const hasDistress = distressTriggers.some(dt => 
      triggerLower.includes(dt) || 
      feedbackLower.includes(dt) || 
      feedbackLower.includes(dt.replace('_', ' '))
    );

    if (hasDistress && (!task.priority_score || task.priority_score < 8)) {
      task.priority_score = 9; // Escalate automatically to Level 9
    }

    // 4. Save raw feedback straight into public.user_feedback table in Supabase
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const { error } = await supabase
      .from('user_feedback')
      .insert([{
        user_id: 'abdc2c94-1338-4bd6-9b31-e8d056b6e11d',
        feature: task.feature_title ? task.feature_title.toLowerCase().replace(/[^a-z0-9_]/g, '_') : 'emotional_checkin',
        screen: 'sandbox_analytics',
        feedback_type: 'Addition of New Feature',
        feedback: feedback,
        emotion: emotion || task.target_emotion || 'neutral',
        trigger: trigger || 'general',
        metadata: { source: "sandbox_telemetry_loop", app_version: "1.0.0" }
      }])
      .select();

    if (error) {
      return NextResponse.json({ error: `Supabase write error: ${error.message}` }, { status: 500 });
    }

    return NextResponse.json({ success: true, task });

  } catch (err: unknown) {
    return NextResponse.json({ error: `Server exception: ${(err as Error).message}` }, { status: 500 });
  }
}
