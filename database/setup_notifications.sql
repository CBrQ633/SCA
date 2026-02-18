-- Create a table to store FCM tokens (optional, if you want to manage them manually, 
-- but usually stored in users table or separate profile table)
-- We will assume we store fcm_token in 'users' table or 'profiles' table.
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS fcm_token TEXT;
-- Trigger Function to send notification on New News
-- Note: This requires the 'http' extension to be enabled in Supabase to call FCM API
-- OR use a Supabase Edge Function. Since we are writing SQL, we will define the Trigger
-- that CALLS the Edge Function (conceptually).
-- 1. Enable pg_net extension (if not enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;
-- 2. Function to Notify on New News
CREATE OR REPLACE FUNCTION public.handle_new_news() RETURNS TRIGGER AS $$ BEGIN -- Call Edge Function 'send-push-notification'
    -- Payload: { "type": "news", "title": NEW.title, "body": NEW.content }
    PERFORM net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
        body := jsonb_build_object(
            'type',
            'news',
            'title',
            NEW.title,
            'body',
            left(NEW.content, 100) -- Truncate content for body
        )
    );
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 3. Create Trigger
DROP TRIGGER IF EXISTS on_news_created ON public.news_announcements;
CREATE TRIGGER on_news_created
AFTER
INSERT ON public.news_announcements FOR EACH ROW EXECUTE PROCEDURE public.handle_new_news();
-- 4. Function for Subscription Expiry (To be called by pg_cron)
-- We need to enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;
-- Schedule job to run every day at 10 AM
SELECT cron.schedule(
        'notify_expiring_subscriptions',
        '0 10 * * *',
        -- At 10:00 AM every day
        $$
        SELECT net.http_post(
                url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/notify-subscription-expiry',
                headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
                body := '{}'::jsonb
            ) $$
    );