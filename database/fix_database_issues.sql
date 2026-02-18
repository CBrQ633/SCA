-- Fix Database Issues Script
-- Run this in your Supabase SQL Editor
-- 1. Add expiry_date column to news_announcements table (if not exists)
ALTER TABLE public.news_announcements
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;
COMMENT ON COLUMN public.news_announcements.expiry_date IS 'Date when the announcement automatically becomes inactive';
-- 2. Create a new delete_user function with proper UUID type handling
CREATE OR REPLACE FUNCTION public.delete_user_v2(target_user_id UUID) RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$ BEGIN -- Only allow admins to delete users
    IF NOT EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
            AND role = 'admin'
    ) THEN RAISE EXCEPTION 'Only admins can delete users';
END IF;
-- Delete from users table (this will cascade to related tables if configured)
DELETE FROM public.users
WHERE id = target_user_id;
-- Delete from auth.users (requires service role or proper permissions)
DELETE FROM auth.users
WHERE id = target_user_id;
END;
$$;
-- Grant execute permission to authenticated users (admin check is inside the function)
GRANT EXECUTE ON FUNCTION public.delete_user_v2(UUID) TO authenticated;
COMMENT ON FUNCTION public.delete_user_v2 IS 'Securely delete a user account (admin only)';