begin;
create table if not exists public.ad_settings (
 id boolean primary key default true check(id),
 stripe_payment_link text not null default '' check(stripe_payment_link = '' or stripe_payment_link ~ '^https://buy[.]stripe[.]com/[A-Za-z0-9_]+$')
);
alter table public.ad_settings enable row level security;
insert into public.ad_settings(id) values(true) on conflict do nothing;
create policy "Read public advertisement payment link" on public.ad_settings for select to anon,authenticated using(true);
grant select on public.ad_settings to anon,authenticated;
revoke insert,update,delete on public.ad_settings from anon,authenticated;
create or replace function public.set_ad_payment_link(p_link text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') then raise exception 'Not authorized'; end if;
 if trim(p_link) !~ '^https://buy[.]stripe[.]com/[A-Za-z0-9_]+$' then raise exception 'Invalid Stripe Payment Link'; end if;
 update public.ad_settings set stripe_payment_link=trim(p_link) where id;
end; $$;
revoke all on function public.set_ad_payment_link(text) from public,anon;
grant execute on function public.set_ad_payment_link(text) to authenticated;

create or replace function public.submit_paid_ad(p_business_name text,p_image_url text,p_target_url text,p_placement text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 if length(trim(coalesce(p_business_name,''))) not between 2 and 120 then raise exception 'Business name must have 2-120 characters'; end if;
 if p_placement is null or p_placement not in ('banner','sidebar','feed') then raise exception 'Invalid placement'; end if;
 if coalesce(p_image_url,'') !~ '^https://[^/[:space:]]+[.][^[:space:]]+' or length(p_image_url)>2048
 or coalesce(p_target_url,'') !~ '^https://[^/[:space:]]+[.][^[:space:]]+' or length(p_target_url)>2048 then raise exception 'Valid HTTPS URLs required'; end if;
 perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
 if (select count(*) from public.paid_ads where user_id=auth.uid() and created_at>now()-interval '1 hour')>=5 then raise exception 'Submission limit reached. Try again later.'; end if;
 insert into public.paid_ads(user_id,business_name,image_url,target_url,placement,price_eur,payment_status,status)
 values(auth.uid(),trim(p_business_name),trim(p_image_url),trim(p_target_url),p_placement,9.99,'unpaid','draft') returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.submit_paid_ad(text,text,text,text) from public,anon;
grant execute on function public.submit_paid_ad(text,text,text,text) to authenticated;
create or replace function public.my_paid_ads() returns jsonb language sql security definer set search_path='' as $$
 select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc),'[]'::jsonb) from
 (select id,business_name,image_url,target_url,placement,price_eur,status,payment_status,starts_at,expires_at,created_at from public.paid_ads where user_id=auth.uid()) a;
$$;
revoke all on function public.my_paid_ads() from public,anon;
grant execute on function public.my_paid_ads() to authenticated;
create or replace function public.admin_paid_ads() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') then raise exception 'Not authorized'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc),'[]'::jsonb) from
 (select p.*,u.email as customer_email from public.paid_ads p left join auth.users u on u.id=p.user_id) a);
end; $$;
revoke all on function public.admin_paid_ads() from public,anon;
grant execute on function public.admin_paid_ads() to authenticated;

create table if not exists public.listing_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references auth.users(id),
 listing_id uuid not null references public.listings(id),
 listing_title text not null,
 reason text not null check(reason in ('suspected_fraud','misleading_description','terms_not_met','other')),
 description text not null check(length(description) between 20 and 4000),
 status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')),
 admin_note text not null default '' check(length(admin_note)<=2000),
 created_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id)
);
create index if not exists listing_reports_queue on public.listing_reports(status,created_at desc);
alter table public.listing_reports enable row level security;
create policy "Administrators read complaints" on public.listing_reports for select to authenticated using(exists(select 1 from public.user_roles where user_id=auth.uid() and role in ('owner','admin')));
grant select on public.listing_reports to authenticated;
revoke insert,update,delete on public.listing_reports from anon,authenticated;
create or replace function public.submit_listing_report(p_listing_id uuid,p_reason text,p_description text) returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_title text;
begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 if p_reason is null or p_reason not in ('suspected_fraud','misleading_description','terms_not_met','other') then raise exception 'Invalid reason'; end if;
 if length(trim(coalesce(p_description,''))) not between 20 and 4000 then raise exception 'Describe the problem in 20-4000 characters'; end if;
 select title into v_title from public.listings where id=p_listing_id and status='published';
 if not found then raise exception 'Listing is no longer available'; end if;
 perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
 if exists(select 1 from public.listing_reports where reporter_id=auth.uid() and listing_id=p_listing_id and status in ('open','reviewing')) then raise exception 'You already have an open report for this listing'; end if;
 if (select count(*) from public.listing_reports where reporter_id=auth.uid() and created_at>now()-interval '1 hour')>=5 then raise exception 'Report limit reached. Try again later.'; end if;
 insert into public.listing_reports(reporter_id,listing_id,listing_title,reason,description) values(auth.uid(),p_listing_id,v_title,p_reason,trim(p_description)) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.submit_listing_report(uuid,text,text) from public,anon;
grant execute on function public.submit_listing_report(uuid,text,text) to authenticated;
create or replace function public.admin_listing_reports() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Not authorized'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc),'[]'::jsonb) from
 (select r.*,u.email as reporter_email,l.description as listing_description,l.status as listing_status,l.contact_value as listing_contact
 from public.listing_reports r left join auth.users u on u.id=r.reporter_id left join public.listings l on l.id=r.listing_id) a);
end; $$;
revoke all on function public.admin_listing_reports() from public,anon;
grant execute on function public.admin_listing_reports() to authenticated;
create or replace function public.review_listing_report(p_report_id uuid,p_status text,p_note text,p_hide_listing boolean default false) returns void language plpgsql security definer set search_path='' as $$
declare v_listing uuid;
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role in ('owner','admin')) then raise exception 'Not authorized'; end if;
 if p_status is null or p_status not in ('reviewing','resolved','dismissed') or length(coalesce(p_note,''))>2000 then raise exception 'Invalid review'; end if;
 select listing_id into v_listing from public.listing_reports where id=p_report_id for update;
 if not found then raise exception 'Report not found'; end if;
 if p_hide_listing then
  if p_status <> 'resolved' or length(trim(coalesce(p_note,'')))<5 then raise exception 'A resolution note is required to hide a listing'; end if;
  update public.listings set status='rejected',reviewed_by=auth.uid(),reviewed_at=now() where id=v_listing and status='published';
 end if;
 update public.listing_reports set status=p_status,admin_note=trim(coalesce(p_note,'')),reviewed_by=auth.uid(),reviewed_at=now() where id=p_report_id;
end; $$;
revoke all on function public.review_listing_report(uuid,text,text,boolean) from public,anon;
grant execute on function public.review_listing_report(uuid,text,text,boolean) to authenticated;
commit;
