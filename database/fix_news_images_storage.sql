-- =============================================
-- Storage Policies for news_images bucket
-- Run this in Supabase SQL Editor
-- =============================================
-- 1. First, ensure the bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('news_images', 'news_images', true) ON CONFLICT (id) DO
UPDATE
SET public = true;
-- 2. Drop existing policies (in case they exist and are broken)
DROP POLICY IF EXISTS "Anyone can view news images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload news images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete news images" ON storage.objects;
-- 3. Allow ANYONE to VIEW/DOWNLOAD images (public read)
CREATE POLICY "Anyone can view news images" ON storage.objects FOR
SELECT USING (bucket_id = 'news_images');
-- 4. Allow authenticated users to UPLOAD images
CREATE POLICY "Authenticated users can upload news images" ON storage.objects FOR
INSERT WITH CHECK (
        bucket_id = 'news_images'
        AND auth.role() = 'authenticated'
    );
-- 5. Allow authenticated users to DELETE their images
CREATE POLICY "Authenticated users can delete news images" ON storage.objects FOR DELETE USING (
    bucket_id = 'news_images'
    AND auth.role() = 'authenticated'
);
-- =============================================
-- VERIFY: After running, check in Supabase Dashboard:
-- Storage → news_images → Policies
-- You should see 3 policies listed
-- =============================================