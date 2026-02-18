-- 🛡️ ADMIN DASHBOARD DATA VISIBILITY FIX
-- Run this in the Supabase SQL Editor to allow Admins to see system-wide statistics.
-- 1. Ensure the is_admin() helper function exists and is robust
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$ BEGIN RETURN EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 2. Add "Admin" access policies for Call Lists
DROP POLICY IF EXISTS "Admins can view all lists" ON public.call_lists;
CREATE POLICY "Admins can view all lists" ON public.call_lists FOR
SELECT TO authenticated USING (public.is_admin());
-- 3. Add "Admin" access policies for Call Items (Matches ReportsRepository queries)
DROP POLICY IF EXISTS "Admins can view all call items" ON public.call_list_items;
CREATE POLICY "Admins can view all call items" ON public.call_list_items FOR
SELECT TO authenticated USING (public.is_admin());
-- 4. Add "Admin" access policies for Call Entries (Used for export and details)
DROP POLICY IF EXISTS "Admins can view all call entries" ON public.call_entries;
CREATE POLICY "Admins can view all call entries" ON public.call_entries FOR
SELECT TO authenticated USING (public.is_admin());
-- 5. Ensure Admin can also view all Users (Required for user/sub stats)
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
CREATE POLICY "Admins can view all users" ON public.users FOR
SELECT TO authenticated USING (public.is_admin());
-- ✅ Done! Now the Admin Dashboard will show real data instead of zeros.