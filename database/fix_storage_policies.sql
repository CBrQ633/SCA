-- 🛡️ STORAGE POLICIES FIX (v2)
-- Run this in your Supabase SQL Editor
-- 1. NEWS IMAGES
DROP POLICY IF EXISTS "Anyone can view news images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload news images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update/delete news images" ON storage.objects;
CREATE POLICY "Anyone can view news images" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'news_images');
CREATE POLICY "Admins can upload news images" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'news_images'
        AND (
            SELECT role
            FROM public.users
            WHERE id = auth.uid()
        ) = 'admin'
    );
CREATE POLICY "Admins can update/delete news images" ON storage.objects FOR ALL TO authenticated USING (
    bucket_id = 'news_images'
    AND (
        SELECT role
        FROM public.users
        WHERE id = auth.uid()
    ) = 'admin'
);
-- 2. PAYMENT PROOFS
DROP POLICY IF EXISTS "Users can upload their own proofs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own proofs" ON storage.objects;
CREATE POLICY "Users can upload their own proofs" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (bucket_id = 'payment_proofs');
CREATE POLICY "Admins can view all payment proofs" ON storage.objects FOR
SELECT TO authenticated USING (
        bucket_id = 'payment_proofs'
        AND (
            SELECT role
            FROM public.users
            WHERE id = auth.uid()
        ) = 'admin'
    );
CREATE POLICY "Users can view their own proofs" ON storage.objects FOR
SELECT TO authenticated USING (
        bucket_id = 'payment_proofs'
        AND (storage.foldername(name)) [1] = auth.uid()::text
    );
-- ✅ Storage policies configured correctly!