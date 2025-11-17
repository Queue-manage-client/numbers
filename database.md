-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.ai_chat_logs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL,
  question text NOT NULL,
  answer text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_chat_logs_pkey PRIMARY KEY (id),
  CONSTRAINT ai_chat_logs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.chat_messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  room_id uuid NOT NULL,
  profile_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chat_messages_pkey PRIMARY KEY (id),
  CONSTRAINT chat_messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id),
  CONSTRAINT chat_messages_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.chat_room_members (
  room_id uuid NOT NULL,
  profile_id uuid NOT NULL,
  CONSTRAINT chat_room_members_pkey PRIMARY KEY (room_id, profile_id),
  CONSTRAINT chat_room_members_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_rooms(id),
  CONSTRAINT chat_room_members_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.chat_rooms (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  room_type text CHECK (room_type = ANY (ARRAY['direct'::text, 'group'::text])),
  company_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chat_rooms_pkey PRIMARY KEY (id),
  CONSTRAINT chat_rooms_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id)
);
CREATE TABLE public.companies (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  address text,
  industry text,
  website text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT companies_pkey PRIMARY KEY (id)
);
CREATE TABLE public.company_videos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL,
  video_path text NOT NULL,
  thumbnail_path text,
  title text,
  description text,
  vertical boolean DEFAULT true,
  is_public boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  tags ARRAY DEFAULT '{}'::text[],
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT company_videos_pkey PRIMARY KEY (id),
  CONSTRAINT company_videos_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id)
);
CREATE TABLE public.inquiries (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  profile_id uuid NOT NULL,
  subject text NOT NULL,
  message text NOT NULL,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'progress'::text, 'resolved'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT inquiries_pkey PRIMARY KEY (id),
  CONSTRAINT inquiries_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.internships (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  start_date date,
  end_date date,
  is_public boolean DEFAULT true,
  tags ARRAY,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT internships_pkey PRIMARY KEY (id),
  CONSTRAINT internships_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id)
);
CREATE TABLE public.job_applications (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  job_id uuid NOT NULL,
  user_id uuid NOT NULL,
  status text DEFAULT 'applied'::text CHECK (status = ANY (ARRAY['applied'::text, 'messaging'::text, 'rejected'::text, 'accepted'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT job_applications_pkey PRIMARY KEY (id),
  CONSTRAINT job_applications_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id),
  CONSTRAINT job_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.jobs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  salary text,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'closed'::text])),
  location USER-DEFINED,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT jobs_pkey PRIMARY KEY (id),
  CONSTRAINT jobs_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  role text NOT NULL CHECK (role = ANY (ARRAY['user'::text, 'company_user'::text, 'admin'::text])),
  company_id uuid,
  position text,
  department text,
  nickname text,
  gender text,
  birth_date date,
  location text,
  university text,
  skills ARRAY,
  job_preferences jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id)
);
CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);