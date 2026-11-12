begin;
do $$
declare a uuid; r uuid; o uuid; u uuid; l uuid; amount numeric; s timestamptz; e timestamptz;
begin
 perform set_config('request.jwt.claim.sub','',true);
 begin perform public.submit_paid_ad('Test','https://example.com/banner.png','https://example.com','banner'); raise exception 'TEST FAILED: anonymous submission allowed';
 exception when others then if sqlerrm <> 'Login required' then raise; end if; end;
 begin perform public.admin_listing_reports(); raise exception 'TEST FAILED: anonymous reports access allowed';
 exception when others then if sqlerrm <> 'Not authorized' then raise; end if; end;
 select user_id into o from public.user_roles where role='owner' limit 1;
 if o is null then raise exception 'TEST FAILED: no owner available'; end if;
 perform set_config('request.jwt.claim.sub',o::text,true);
 begin perform public.submit_paid_ad('Test','http://example.com/banner.png','https://example.com','banner'); raise exception 'TEST FAILED: insecure image allowed';
 exception when others then if sqlerrm <> 'Valid HTTPS URLs required' then raise; end if; end;
 select au.id into u from auth.users au left join public.user_roles ur on ur.user_id=au.id where coalesce(ur.role,'user')<>'owner' limit 1;
 if u is null then
  u:=gen_random_uuid();
  insert into auth.users(id,email,aud,role,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values(u,'payment-test-'||u::text||'@example.invalid','authenticated','authenticated',now(),'{"provider":"email","providers":["email"]}','{}',now(),now());
 end if;
 perform set_config('request.jwt.claim.sub',u::text,true);
 a:=public.submit_paid_ad('TRANSACTION TEST - NOT PUBLISHED','https://example.com/banner.png','https://example.com','banner');
 perform set_config('request.jwt.claim.sub',o::text,true);
 select price_eur into amount from public.paid_ads where id=a;
 if amount<>9.99 then raise exception 'TEST FAILED: incorrect price'; end if;
 begin perform public.activate_paid_ad(a); raise exception 'TEST FAILED: unpaid activation allowed';
 exception when others then if sqlerrm <> 'Ad is unpaid, expired or unavailable' then raise; end if; end;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
 begin perform public.confirm_paid_ad(a); raise exception 'TEST FAILED: client confirmed payment';
 exception when others then if sqlerrm <> 'Only owner can confirm payment' then raise; end if; end;
 begin perform public.review_listing_report(gen_random_uuid(),'resolved','test',false); raise exception 'TEST FAILED: client reviewed report';
 exception when others then if sqlerrm <> 'Not authorized' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',o::text,true);
 perform public.confirm_paid_ad(a);
 perform public.activate_paid_ad(a);
 select starts_at,expires_at into s,e from public.paid_ads where id=a;
 if s is null or e-s<>interval '30 days' then raise exception 'TEST FAILED: incorrect advertising dates'; end if;
 perform public.pause_paid_ad(a);
 select id into l from public.listings limit 1;
 if l is null then
  perform set_config('request.jwt.claim.sub',(select id::text from public.profiles limit 1),true);
  insert into public.listings(owner_id,title,description,category,country_code,city,contact_method,contact_value,status)
  values((select id from public.profiles limit 1),'TRANSACTION TEST ONLY','Transactional report test, rolled back immediately.','jobs','DE','Berlin','whatsapp','+491234567890','published') returning id into l;
 else
  update public.listings set status='published' where id=l;
 end if;
 perform set_config('request.jwt.claim.sub',o::text,true);
 if exists(select 1 from public.listings where id=l and status='pending') then perform public.review_listing(l,'approved'); end if;
 if l is not null then
  r:=public.submit_listing_report(l,'terms_not_met','Transactional test only; nothing will be saved.');
  begin perform public.submit_listing_report(l,'terms_not_met','Duplicate transactional report should be rejected.'); raise exception 'TEST FAILED: duplicate report accepted';
  exception when others then if sqlerrm <> 'You already have an open report for this listing' then raise; end if; end;
  perform public.review_listing_report(r,'resolved','Transactional moderation test',true);
  if not exists(select 1 from public.listings where id=l and status='rejected') then raise exception 'TEST FAILED: listing was not hidden'; end if;
 else
  raise exception 'TEST INCOMPLETE: no published listing available for report test';
 end if;
end $$;
rollback;
select 'PASS: login, HTTPS, fixed price, unpaid activation denied, owner-only payment, private moderation, 30-day dates, duplicate protection, hide listing; ALL test changes rolled back' as result;
