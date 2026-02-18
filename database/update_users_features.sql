-- Add columns for single session and trial tracking
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS last_session_id UUID,
    ADD COLUMN IF NOT EXISTS trial_used BOOLEAN DEFAULT false;
-- Add a comment for documentation
COMMENT ON COLUMN public.users.last_session_id IS 'Stores the last active session ID for single-device enforcement.';
COMMENT ON COLUMN public.users.trial_used IS 'Tracks if the user has already utilized their trial period.';