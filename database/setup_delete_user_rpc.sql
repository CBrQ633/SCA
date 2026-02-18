-- Function to delete a user completely
-- To be called by Admin using Supabase RPC
-- Note: Deleting from auth.users requires elevated privileges.
-- This function MUST be created in the Supabase Dashboard SQL Editor to work properly.
CREATE OR REPLACE FUNCTION public.delete_user_account(target_user_id UUID) RETURNS VOID AS $$ BEGIN -- Delete from public.users (Profile)
    -- If you have ON DELETE CASCADE set up, this might happen automatically when deleting auth.users
    -- But since we can't easily delete auth.users from here without pg_net or elevated rights...
    -- Step 1: Delete all related data in public schema (manually if no Cascade)
DELETE FROM public.news_announcements
WHERE created_by = target_user_id::text;
DELETE FROM public.call_lists
WHERE user_id = target_user_id::text;
DELETE FROM public.subscription_requests
WHERE user_id = target_user_id::text;
DELETE FROM public.users
WHERE id = target_user_id;
-- Step 2: Delete from auth.users
-- This is tricky. Regular postgres functions cannot access auth.users easily.
-- You often need a "Service Key" or correct grants.
-- WORKAROUND: We leave the auth.user but since the profile is gone, the app treats them as non-existent
-- OR, better, use the Supabase Management API (Edge Function) for full cleanup.
-- ATTEMPT (Might fail if not Superuser):
-- DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;