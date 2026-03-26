-- EMERGENCY FIX SCRIPT
-- Run this in Supabase SQL Editor immediately to fix access issues.
-- 1. Disable RLS temporarily to allow fixes (optional, but good for safety during fix)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
-- 2. Drop problematic policies that might cause recursion
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
-- Added this
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
-- Added this
DROP POLICY IF EXISTS "Admins have full access to news" ON public.news_announcements;
DROP POLICY IF EXISTS "Anyone can view active news" ON public.news_announcements;
-- Added this
DROP POLICY IF EXISTS "Admins full access news" ON public.news_announcements;
-- Added this
DROP POLICY IF EXISTS "Admins view all requests" ON public.subscription_requests;
DROP POLICY IF EXISTS "Users view own requests" ON public.subscription_requests;
-- Added this
DROP POLICY IF EXISTS "Users insert own requests" ON public.subscription_requests;
-- Added this
DROP POLICY IF EXISTS "Admins full access requests" ON public.subscription_requests;
-- Added this
DROP POLICY IF EXISTS "Users full access own lists" ON public.call_lists;
-- Added this
DROP POLICY IF EXISTS "Users full access own list items" ON public.call_list_items;
-- Added this
-- 3. Create a Secure Function to check Admin status (Prevents Recursion)
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$ BEGIN RETURN EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 4. Re-create Optimized Policies using the Function
-- USERS Table
CREATE POLICY "Users can view own profile" ON public.users FOR
SELECT USING (auth.uid() = id);
-- Allow Admins to view all users (using the function)
CREATE POLICY "Admins can view all users" ON public.users FOR
SELECT USING (public.is_admin());
-- Also allow Admins to UPDATE users (to fix roles if needed)
CREATE POLICY "Admins can update users" ON public.users FOR
UPDATE USING (public.is_admin());
-- NEWS Table
CREATE POLICY "Anyone can view active news" ON public.news_announcements FOR
SELECT USING (is_active = true);
CREATE POLICY "Admins full access news" ON public.news_announcements FOR ALL USING (public.is_admin());
-- SUBSCRIPTION REQUESTS Table
CREATE POLICY "Users view own requests" ON public.subscription_requests FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own requests" ON public.subscription_requests FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins full access requests" ON public.subscription_requests FOR ALL USING (public.is_admin());
-- CALL LISTS Table
CREATE POLICY "Users full access own lists" ON public.call_lists FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users full access own list items" ON public.call_list_items FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM public.call_lists
        WHERE id = public.call_list_items.list_id
            AND user_id = auth.uid()
    )
);
-- 5. Enable RLS again
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- 6. RESTORE ADMIN ROLE (Run this line with your specific email)
-- Replace 'YOUR_EMAIL_HERE' with your admin email, e.g., 'it@babeco.org'
UPDATE public.users
SET role = 'admin'
WHERE email = 'it@babeco.org';
-- Change this to your email if different