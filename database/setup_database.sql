-- SQL Setup for Smart Call Assistant (SCA)
-- This script ensures all necessary tables exist with the correct schema.
-- Note: 'users' table is preserved to keep existing account data.
-- 1. Users Table (Ensure it exists with all required columns)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    full_name TEXT,
    email TEXT,
    role TEXT DEFAULT 'user',
    -- 'user' or 'admin'
    subscription_status TEXT DEFAULT 'inactive',
    -- 'active', 'inactive', 'pending'
    subscription_start TIMESTAMP WITH TIME ZONE,
    subscription_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 2. Subscription Requests (Drop and Recreate for clean schema)
DROP TABLE IF EXISTS public.subscription_requests CASCADE;
CREATE TABLE public.subscription_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    plan_type TEXT NOT NULL,
    -- 'monthly', 'quarterly'
    amount DOUBLE PRECISION DEFAULT 0.0,
    payment_screenshot_url TEXT,
    status TEXT DEFAULT 'pending',
    -- 'pending', 'approved', 'rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES public.users(id)
);
-- 3. News Announcements (Simplified Schema)
DROP TABLE IF EXISTS public.news_announcements CASCADE;
CREATE TABLE public.news_announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    title_ar TEXT,
    -- Added for backward compatibility if needed
    content_ar TEXT,
    -- Added for backward compatibility if needed
    image_urls TEXT [] DEFAULT '{}',
    created_by UUID REFERENCES public.users(id) ON DELETE
    SET NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 4. Call Lists
DROP TABLE IF EXISTS public.call_lists CASCADE;
CREATE TABLE public.call_lists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 5. Call List Items (Detailed entries)
DROP TABLE IF EXISTS public.call_list_items CASCADE;
CREATE TABLE public.call_list_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID REFERENCES public.call_lists(id) ON DELETE CASCADE NOT NULL,
    name TEXT,
    phone TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    -- 'pending', 'called', 'no_answer', etc.
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- 6. Call Entries (Alternate table used in some repository methods)
DROP TABLE IF EXISTS public.call_entries CASCADE;
CREATE TABLE public.call_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    list_id UUID REFERENCES public.call_lists(id) ON DELETE CASCADE NOT NULL,
    phone_number TEXT NOT NULL,
    customer_name TEXT,
    status TEXT DEFAULT 'pending',
    position INTEGER DEFAULT 0,
    called_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_entries ENABLE ROW LEVEL SECURITY;
-- Basic Policies (Adjust based on your specific security needs)
-- Users: Can read their own data, Admins can read all.
CREATE POLICY "Users can view own data" ON public.users FOR
SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM public.users
            WHERE id = auth.uid()
                AND role = 'admin'
        )
    );
-- News: Everyone can view active news. Admins can do everything.
CREATE POLICY "Anyone can view active news" ON public.news_announcements FOR
SELECT USING (is_active = true);
CREATE POLICY "Admins have full access to news" ON public.news_announcements FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    )
);
-- Subscriptions: Users can see and create their own, Admins can manage all.
CREATE POLICY "Users view own requests" ON public.subscription_requests FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own requests" ON public.subscription_requests FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view all requests" ON public.subscription_requests FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    )
);
-- Call Lists: Users see their own.
CREATE POLICY "Users access own call lists" ON public.call_lists FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users access own list items" ON public.call_list_items FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.call_lists
        WHERE id = list_id
            AND user_id = auth.uid()
    )
);
CREATE POLICY "Users access own call entries" ON public.call_entries FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.call_lists
        WHERE id = list_id
            AND user_id = auth.uid()
    )
);