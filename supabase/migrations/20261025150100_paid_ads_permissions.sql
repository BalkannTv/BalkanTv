begin;
drop policy if exists "Admins can manage paid ads" on public.paid_ads;
create policy "Administrators read paid ads" on public.paid_ads for select to authenticated using(exists(select 1 from public.user_roles where user_id=auth.uid() and role in ('owner','admin')));
create policy "Owner creates unpaid drafts" on public.paid_ads for insert to authenticated with check(
 exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner')
 and payment_status='unpaid' and status='draft' and starts_at is null and expires_at is null
);
commit;
