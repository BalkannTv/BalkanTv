begin;
alter table public.listings drop constraint listings_category_check;
alter table public.listings add constraint listings_category_check check(category in ('jobs','rides','housing','services','vehicles','home_goods','electronics','other'));
commit;