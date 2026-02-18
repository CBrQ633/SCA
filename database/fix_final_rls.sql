-- 🚨 FINAL FIX: USERS TABLE RLS RECURSION & ADMIN ROLE
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)
-- 1. Create a safe helper function to check admin status
-- This function uses "SECURITY DEFINER" to bypass RLS during the check
CREATE OR REPLACE FUNCTION public.is_admin_v2() RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$ BEGIN RETURN EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    );
END;
$$;
-- 2. Drop all potentially problematic policies on the users table
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Allow Admins Full Access" ON public.users;
-- 3. Re-create clean policies using the safe helper function
-- Everyone can view their own profile
CREATE POLICY "Users can view own profile" ON public.users FOR
SELECT USING (auth.uid() = id);
-- Admins can do anything to any user record
CREATE POLICY "Admins full access" ON public.users FOR ALL TO authenticated USING (public.is_admin_v2());
-- 4. Fix News policies
DROP POLICY IF EXISTS "Admins have full access to news" ON public.news_announcements;
CREATE POLICY "Admins full access to news" ON public.news_announcements FOR ALL TO authenticated USING (public.is_admin_v2());
-- 5. Fix Subscription policies
DROP POLICY IF EXISTS "Admins view all requests" ON public.subscription_requests;
CREATE POLICY "Admins full access to requests" ON public.subscription_requests FOR ALL TO authenticated USING (public.is_admin_v2());
-- 6. 🛡️ ENSURE YOUR ACCOUNT IS ADMIN
-- REPLACE 'your-email@example.com' with your actual email
UPDATE public.users
SET role = 'admin'
WHERE email = 'your-email@example.com';
-- ✅ FIXED! Please refresh your app.