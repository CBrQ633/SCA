-- 🚨 FIX: Allow users to update their own Last Session ID
-- This is required for the "Single Device Login" feature to work.
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/_/sql
-- 1. Enable UPDATE for users on their own row
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users FOR
UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
-- 2. Double check: Ensure admin can view and manage everyone
DROP POLICY IF EXISTS "Admins full access" ON public.users;
CREATE POLICY "Admins full access" ON public.users FOR ALL TO authenticated USING (public.is_admin_v2());
-- 3. Verify admin role for your specific email (Replace with your email)
UPDATE public.users
SET role = 'admin',
    subscription_status = 'active'
WHERE email = 'your-email@example.com';
-- ✅ Done! Now single session will work correctly.