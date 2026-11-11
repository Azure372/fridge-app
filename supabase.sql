-- 冷蔵庫管理アプリ「家族と共有」用のテーブルと関数
-- Supabase ダッシュボード → SQL Editor にそのまま貼り付けて Run すると作成されます。
-- テーブルは直接アクセス不可（RLS有効・権限なし）。アプリは下の2つの関数だけを呼びます。

create table if not exists public.fridge_shares (
  code text primary key,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
alter table public.fridge_shares enable row level security;
revoke all on table public.fridge_shares from anon, authenticated;

-- 読み取り: コードが一致する行の状態を返す（なければ null）
create or replace function public.fridge_get(p_code text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  if p_code is null or length(p_code) < 10 or length(p_code) > 40 then
    raise exception 'bad code';
  end if;
  select state, updated_at into r from fridge_shares where code = p_code;
  if not found then return null; end if;
  return jsonb_build_object('state', r.state, 'updated_at', r.updated_at);
end $$;

-- 書き込み: p_base より後に他の端末が更新していれば conflict と現在の状態を返す
create or replace function public.fridge_put(p_code text, p_state jsonb, p_base timestamptz default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare cur timestamptz; r record; ts timestamptz;
begin
  if p_code is null or length(p_code) < 10 or length(p_code) > 40 then
    raise exception 'bad code';
  end if;
  if pg_column_size(p_state) > 1000000 then
    raise exception 'state too large';
  end if;
  select updated_at into cur from fridge_shares where code = p_code for update;
  if found and p_base is not null and cur > p_base + interval '1 millisecond' then
    select state, updated_at into r from fridge_shares where code = p_code;
    return jsonb_build_object('conflict', true, 'state', r.state, 'updated_at', r.updated_at);
  end if;
  insert into fridge_shares (code, state, updated_at) values (p_code, p_state, now())
    on conflict (code) do update set state = excluded.state, updated_at = now()
    returning updated_at into ts;
  return jsonb_build_object('conflict', false, 'updated_at', ts);
end $$;

revoke all on function public.fridge_get(text) from public;
revoke all on function public.fridge_put(text, jsonb, timestamptz) from public;
grant execute on function public.fridge_get(text) to anon, authenticated;
grant execute on function public.fridge_put(text, jsonb, timestamptz) to anon, authenticated;
