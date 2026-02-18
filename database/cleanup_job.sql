-- 🧹 DATABASE CLEANUP SCRIPT (Older than 3 days)
-- You can run this in Supabase SQL Editor periodically or set up a Cron job.
-- 1. Delete old news announcements
DELETE FROM public.news_announcements
WHERE created_at < NOW() - INTERVAL '3 days';
-- 2. Delete old subscription requests (and their associated screenshots)
-- Note: This deletes the database record. 
-- For physical file deletion from Storage, you'd normally use a Supabase Edge Function or check storage.objects.
DELETE FROM public.subscription_requests
WHERE created_at < NOW() - INTERVAL '3 days';
-- 🚀 To automate this, enable 'pg_cron' in your Supabase dashboard and run:
-- SELECT cron.schedule('daily-cleanup', '0 0 * * *', $$ 
--   DELETE FROM public.news_announcements WHERE created_at < NOW() - INTERVAL '3 days';
--   DELETE FROM public.subscription_requests WHERE created_at < NOW() - INTERVAL '3 days';
-- $$);