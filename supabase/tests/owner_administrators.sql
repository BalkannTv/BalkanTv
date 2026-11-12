begin;
do $$
declare o uuid; u uuid; mail text; a uuid; free_ad uuid; l uuid; role_value text;
begin
 select user_id into o from public.user_roles where role='owner' limit 1;
 if o is null then raise exception 'TEST: no owner'; end if;
 select au.id,au.email into u,mail from auth.users au left join public.user_roles r on r.user_id=au.id
 where coalesce(r.role,'user')='user' and au.email_confirmed_at is not null and au.deleted_at is null limit 1;
 if u is null then
  u:=gen_random_uuid(); mail:='role-test-'||u::text||'@example.invalid';
  insert into auth.users(id,email,aud,role,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values(u,mail,'authenticated','authenticated',now(),'{"provider":"email","providers":["email"]}','{}',now(),now());
 end if;
 perform set_config('request.jwt.claim.sub','',true);
 begin perform public.owner_administrators(); raise exception 'TEST: anonymous read allowed'; exception when others then if sqlerrm<>'Owner access required' then raise; end if; end;
 perform set_config('request.jwt.claim.sub',u::text,true);
 begin perform public.owner_set_administrator(u,true); raise exception 'TEST: self promotion allowed'; exception when others then if sqlerrm<>'Owner access required' then raise; end if; end;
 a:=public.submit_paid_ad('TRANSACTION CUSTOMER TEST','https://example.com/ad.png','https://example.com','banner');
 if not exists(select 1 from public.paid_ads where id=a and price_eur=9.99 and payment_status='unpaid' and status='draft') then raise exception 'TEST: customer exempted from payment'; end if;
 perform set_config('request.jwt.claim.sub',o::text,true);
 if (public.owner_find_administrator(upper(mail))->0->>'user_id')<>u::text then raise exception 'TEST: email search failed'; end if;
 begin perform public.owner_set_administrator(o,false); raise exception 'TEST: owner demotion allowed'; exception when others then if sqlerrm<>'Owner account is protected' then raise; end if; end;
 perform public.owner_set_administrator(u,true);
 select role into role_value from public.user_roles where user_id=u;
 if role_value<>'admin' then raise exception 'TEST: owner promotion failed'; end if;
 if not exists(select 1 from public.administrator_changes where actor_id=o and target_id=u and previous_role='user' and new_role='admin') then raise exception 'TEST: audit missing'; end if;
 free_ad:=public.submit_paid_ad('TRANSACTION OWNER FREE TEST','https://example.com/ad.png','https://example.com','banner');
 if not exists(select 1 from public.paid_ads where id=free_ad and price_eur=0 and payment_status='paid' and status='draft') then raise exception 'TEST: owner ad not free'; end if;
 perform public.activate_paid_ad(free_ad);
 if not exists(select 1 from public.paid_ads where id=free_ad and status='active' and expires_at-starts_at=interval '30 days') then raise exception 'TEST: owner activation failed'; end if;
 perform public.pause_paid_ad(free_ad);
 perform set_config('request.jwt.claim.sub',u::text,true);
 perform public.admin_listing_reports();
 begin perform public.owner_administrators(); raise exception 'TEST: admin can manage admins'; exception when others then if sqlerrm<>'Owner access required' then raise; end if; end;
 begin perform public.owner_set_administrator(o,false); raise exception 'TEST: admin can demote owner'; exception when others then if sqlerrm<>'Owner access required' then raise; end if; end;
 begin perform public.admin_paid_ads(); raise exception 'TEST: admin can read paid ads'; exception when others then if sqlerrm<>'Not authorized' then raise; end if; end;
 begin perform public.set_ad_payment_link('https://buy.stripe.com/test_123'); raise exception 'TEST: admin can change Stripe'; exception when others then if sqlerrm<>'Not authorized' then raise; end if; end;
 begin perform public.confirm_paid_ad(a); raise exception 'TEST: admin can confirm payment'; exception when others then if sqlerrm<>'Only owner can confirm payment' then raise; end if; end;
 begin perform public.activate_paid_ad(a); raise exception 'TEST: admin can publish paid ads'; exception when others then if sqlerrm<>'Only owner can activate ads' then raise; end if; end;
 a:=public.submit_paid_ad('TRANSACTION MODERATOR CUSTOMER TEST','https://example.com/ad.png','https://example.com','banner');
 if not exists(select 1 from public.paid_ads where id=a and price_eur=9.99 and payment_status='unpaid') then raise exception 'TEST: moderator exempted from payment'; end if;
 insert into public.listings(owner_id,title,description,category,country_code,city,contact_method,contact_value)
 values(u,'TRANSACTION MODERATION TEST','Transactional moderation check; all writes rolled back.','jobs','DE','Berlin','whatsapp','+491234567890') returning id into l;
 -- Start a pending listing inside this test transaction to exercise the moderator RPC.
 update public.listings set status='pending' where id=l;
 perform public.review_listing(l,'approved');
 if not exists(select 1 from public.listings where id=l and status='published') then raise exception 'TEST: moderator cannot approve'; end if;
 perform set_config('request.jwt.claim.sub',o::text,true);
 perform public.owner_set_administrator(u,false);
 if not exists(select 1 from public.user_roles where user_id=u and role='user') then raise exception 'TEST: revocation failed'; end if;
 perform set_config('request.jwt.claim.sub',u::text,true);
 begin perform public.review_listing(l,'rejected'); raise exception 'TEST: revoked admin can moderate'; exception when others then if sqlerrm<>'Not authorized' then raise; end if; end;
end $$;
rollback;
select 'PASS: owner-only admin management, protected owner, audit, moderator approval and complaints, no Stripe/paid-ad access, immediate revocation, customer EUR 9.99, owner free with 30-day publication; ALL test changes rolled back' as result;
