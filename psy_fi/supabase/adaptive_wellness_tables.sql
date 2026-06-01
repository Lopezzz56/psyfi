-- Privacy-first adaptive wellness analytics.
-- These tables intentionally store anonymous aggregates only.
-- Do not add raw chat, journal, diary, reflection, or grounding text columns here.

create table if not exists public.emotional_signals (
  id uuid primary key default gen_random_uuid(),
  anonymous_id text not null,
  care_state text not null,
  emotion text not null,
  severity text not null,
  risk_score integer default 0,
  recent_event_count integer default 0,
  recurring_trigger_count integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.intervention_analytics (
  id uuid primary key default gen_random_uuid(),
  anonymous_id text not null,
  intervention_id text not null,
  category text not null,
  action text not null,
  care_state_before text,
  care_state_after text,
  duration_seconds integer,
  effectiveness_score integer,
  source text,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_emotional_snapshots (
  id uuid primary key default gen_random_uuid(),
  anonymous_id text not null,
  date date not null,
  care_state text not null,
  dominant_emotion text not null,
  dominant_severity text not null,
  risk_score integer default 0,
  event_count integer default 0,
  grounding_count integer default 0,
  journal_count integer default 0,
  activation_completed integer default 0,
  activation_skipped integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.anonymous_behavioral_patterns (
  id uuid primary key default gen_random_uuid(),
  anonymous_id text not null,
  date date not null,
  care_state text not null,
  category_counts jsonb default '{}'::jsonb,
  completion_rate numeric default 0,
  emotional_transitions jsonb default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.activation_effectiveness (
  id uuid primary key default gen_random_uuid(),
  anonymous_id text not null,
  intervention_id text not null,
  category text not null,
  care_state_before text,
  care_state_after text,
  effectiveness_score integer,
  created_at timestamptz not null default now()
);

create index if not exists emotional_signals_anon_created_idx
  on public.emotional_signals (anonymous_id, created_at desc);

create index if not exists intervention_analytics_anon_created_idx
  on public.intervention_analytics (anonymous_id, created_at desc);

create index if not exists daily_snapshots_anon_date_idx
  on public.daily_emotional_snapshots (anonymous_id, date desc);

create index if not exists activation_effectiveness_anon_created_idx
  on public.activation_effectiveness (anonymous_id, created_at desc);
