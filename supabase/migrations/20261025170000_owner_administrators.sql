begin;
create table public.administrator_changes (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references auth.users(id),
 target_id uuid not null references auth.users(id),
 previous_role text not null,
 new_role text not null check(new_role in ('user','admin')),
 created_at timestamptz not null default now()
);
alter table public.administrator_changes enable row level security;
create policy "Owner reads administrator history" on public.administrator_changes for select to authenticated using(exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner'));
revoke all on public.administrator_changes from anon,authenticated;
grant select on public.administrator_changes to authenticated;
revoke insert,update,delete on public.user_roles from anon,authenticated;

create function public.owner_administrators() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') then raise exception 'Owner access required'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(a) order by a.role desc,a.email),'[]'::jsonb) from
 (select r.user_id,u.email,r.role,r.created_at from public.user_roles r join auth.users u on u.id=r.user_id where r.role in ('owner','admin'))a);
end; $$;
create function public.owner_find_administrator(p_email text) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') then raise exception 'Owner access required'; end if;
 if p_email is null or length(trim(p_email)) not between 3 and 254 then raise exception 'Enter a registered email'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(a)),'[]'::jsonb) from
 (select u.id as user_id,u.email,coalesce(r.role,'user') as role from auth.users u left join public.user_roles r on r.user_id=u.id
 where lower(u.email)=lower(trim(p_email)) and u.email_confirmed_at is not null and u.deleted_at is null)a);
end; $$;
create function public.owner_set_administrator(p_user_id uuid,p_enable boolean) returns void language plpgsql security definer set search_path='' as $$
declare old_role text;
begin
 if not exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') then raise exception 'Owner access required'; end if;
 if p_enable is null or p_user_id is null then raise exception 'Invalid administrator change'; end if;
 if p_user_id=auth.uid() then raise exception 'Owner account is protected'; end if;
 perform 1 from auth.users where id=p_user_id and deleted_at is null and email_confirmed_at is not null for update;
 if not found then raise exception 'Verified account not found'; end if;
 select role into old_role from public.user_roles where user_id=p_user_id for update;
 old_role:=coalesce(old_role,'user');
 if old_role='owner' then raise exception 'Owner account is protected'; end if;
 if old_role=(case when p_enable then 'admin' else 'user' end) then return; end if;
 insert into public.user_roles(user_id,role) values(p_user_id,case when p_enable then 'admin' else 'user' end)
 on conflict(user_id) do update set role=excluded.role;
 insert into public.administrator_changes(actor_id,target_id,previous_role,new_role)
 values(auth.uid(),p_user_id,old_role,case when p_enable then 'admin' else 'user' end);
end; $$;
revoke all on function public.owner_administrators() from public,anon;
revoke all on function public.owner_find_administrator(text) from public,anon;
revoke all on function public.owner_set_administrator(uuid,boolean) from public,anon;
grant execute on function public.owner_administrators() to authenticated;
grant execute on function public.owner_find_administrator(text) to authenticated;
grant execute on function public.owner_set_administrator(uuid,boolean) to authenticated;
alter policy "Administrators read paid ads" on public.paid_ads using(exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner'));

create or replace function public.submit_paid_ad(p_business_name text,p_image_url text,p_target_url text,p_placement text)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_id uuid; is_owner boolean;
begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 if length(trim(coalesce(p_business_name,''))) not between 2 and 120 then raise exception 'Business name must have 2-120 characters'; end if;
 if p_placement is null or p_placement not in ('banner','sidebar','feed') then raise exception 'Invalid placement'; end if;
 if coalesce(p_image_url,'') !~ '^https://[^/[:space:]]+[.][^[:space:]]+' or length(p_image_url)>2048
 or coalesce(p_target_url,'') !~ '^https://[^/[:space:]]+[.][^[:space:]]+' or length(p_target_url)>2048 then raise exception 'Valid HTTPS URLs required'; end if;
 select exists(select 1 from public.user_roles where user_id=auth.uid() and role='owner') into is_owner;
 perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
 if not is_owner and (select count(*) from public.paid_ads where user_id=auth.uid() and created_at>now()-interval '1 hour')>=5 then raise exception 'Submission limit reached. Try again later.'; end if;
 insert into public.paid_ads(user_id,business_name,image_url,target_url,placement,price_eur,payment_status,status)
 values(auth.uid(),trim(p_business_name),trim(p_image_url),trim(p_target_url),p_placement,
 case when is_owner then 0 else 9.99 end,case when is_owner then 'paid' else 'unpaid' end,'draft') returning id into v_id;
 return v_id;
end; $$;
commit;
