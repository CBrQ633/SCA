-- 🚨 FIX: USERS TABLE RLS RECURSION
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)
-- 1. Create a helper function to check admin status without recursion
-- This function uses "SECURITY DEFINER" to bypass RLS during the check
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$ BEGIN RETURN EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    );
END;
$$;
-- 2. Drop the problematic recursive policy
DROP POLICY IF EXISTS "Allow Admins Full Access" ON public.users;
-- 3. Re-create the policy using the safe helper function
CREATE POLICY "Allow Admins Full Access" ON public.users FOR ALL TO authenticated USING (public.is_admin());
-- ✅ Done! High-five ✋