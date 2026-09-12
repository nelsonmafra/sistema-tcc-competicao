-- =====================================================================
-- Ponto a Ponto — banco no Supabase
--
-- COMO USAR: abra o seu projeto no supabase.com, clique em "SQL Editor",
-- cole este arquivo inteiro e clique em RUN. Pode rodar de novo quantas
-- vezes quiser: nada é apagado, tudo é "crie se não existir".
--
-- O QUE ELE CRIA:
--   * perfis  — quem é treinador e quem é atleta
--   * 6 tabelas de dados, uma por módulo do app (atletas, avaliacoes,
--     metas, torneios, jogos, relatorios). Cada linha é um documento:
--     um id de texto e o conteúdo em JSON, exatamente como o app já usava.
--   * as regras de acesso (Row Level Security):
--       - treinador: acesso total a tudo
--       - atleta: lê o elenco e os jogos (para abrir os relatórios de
--         partida) e lança/edita apenas os jogos que ele mesmo criou.
--         Não vê avaliações, metas, análises de torneio nem relatórios
--         do programa, e não apaga nada.
-- =====================================================================

create extension if not exists pgcrypto;


-- 1) PERFIS -----------------------------------------------------------
create table if not exists public.perfis (
  id        uuid primary key references auth.users(id) on delete cascade,
  nome      text,
  papel     text not null default 'atleta' check (papel in ('treinador','atleta')),
  criado_em timestamptz not null default now()
);

-- papéis: treinador (tudo), atleta, responsavel (só o próprio filho) e
-- pendente — quem criou conta e ainda não usou um convite. Pendente é o novo
-- padrão: conta sem convite não enxerga absolutamente nada.
alter table public.perfis add column if not exists atleta_id text;
alter table public.perfis drop constraint if exists perfis_papel_check;
alter table public.perfis add constraint perfis_papel_check
  check (papel in ('treinador','atleta','responsavel','pendente'));
alter table public.perfis alter column papel set default 'pendente';
alter table public.perfis enable row level security;

-- todo usuário novo entra como PENDENTE, sem acesso a nada; quem tem convite
-- é promovido na hora em que o resgata (ver resgatar_convite, mais abaixo)
create or replace function public.criar_perfil()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfis (id, nome)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists ao_criar_usuario on auth.users;
create trigger ao_criar_usuario after insert on auth.users
  for each row execute function public.criar_perfil();

-- papel de quem está logado. É "security definer" para poder ler a tabela
-- perfis sem cair na própria regra de acesso da tabela perfis.
create or replace function public.papel()
returns text language sql stable security definer set search_path = public as $$
  select coalesce((select p.papel from public.perfis p where p.id = auth.uid()), 'pendente');
$$;

-- qual atleta este usuário pode ver (vazio para treinador e atleta)
create or replace function public.meu_atleta()
returns text language sql stable security definer set search_path = public as $$
  select p.atleta_id from public.perfis p where p.id = auth.uid();
$$;

-- permissão explícita: sem isto, ler a própria linha de perfis pode ser
-- recusado e o app entra com acesso de atleta sem avisar.
grant usage on schema public to authenticated;
grant select on public.perfis to authenticated;
grant update (nome) on public.perfis to authenticated;
revoke all on public.perfis from anon;

drop policy if exists "perfis: cada um ve o seu" on public.perfis;
create policy "perfis: cada um ve o seu" on public.perfis
  for select to authenticated using (id = auth.uid());

drop policy if exists "perfis: treinador administra" on public.perfis;
create policy "perfis: treinador administra" on public.perfis
  for all to authenticated
  using (public.papel() = 'treinador') with check (public.papel() = 'treinador');


-- 2) AS 6 TABELAS DE DADOS -------------------------------------------
create or replace function public.tocar_atualizado()
returns trigger language plpgsql as $$
begin new.atualizado_em = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array['atletas','avaliacoes','metas','torneios','jogos','relatorios'] loop

    execute format('create table if not exists public.%I ('
      || ' id            text primary key default gen_random_uuid()::text,'
      || ' data          jsonb not null default ''{}''::jsonb,'
      || ' criado_por    uuid default auth.uid() references auth.users(id) on delete set null,'
      || ' criado_em     timestamptz not null default now(),'
      || ' atualizado_em timestamptz not null default now())', t);

    execute format('alter table public.%I enable row level security', t);

    execute format('drop trigger if exists ao_atualizar on public.%I', t);
    execute format('create trigger ao_atualizar before update on public.%I'
      || ' for each row execute function public.tocar_atualizado()', t);

    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);

    execute format('drop policy if exists "treinador: acesso total" on public.%I', t);
    execute format('create policy "treinador: acesso total" on public.%I'
      || ' for all to authenticated'
      || ' using (public.papel() = ''treinador'') with check (public.papel() = ''treinador'')', t);

  end loop;
end $$;


-- 3) O QUE CADA PAPEL PODE --------------------------------------------
-- ATLETA: lê o elenco inteiro (para saber de quem é cada jogo).
-- RESPONSÁVEL: lê somente o atleta vinculado a ele. Nada mais.
drop policy if exists "atleta: ler elenco" on public.atletas;
drop policy if exists "ler elenco" on public.atletas;
create policy "ler elenco" on public.atletas
  for select to authenticated
  using ( public.papel() = 'atleta'
          or (public.papel() = 'responsavel' and id = public.meu_atleta()) );

-- jogos: o atleta vê todos; o responsável, só os do filho
drop policy if exists "atleta: ler jogos" on public.jogos;
drop policy if exists "ler jogos" on public.jogos;
create policy "ler jogos" on public.jogos
  for select to authenticated
  using ( public.papel() = 'atleta'
          or (public.papel() = 'responsavel' and data->>'atletaId' = public.meu_atleta()) );

-- o dossiê do filho: avaliações, metas e análises de torneio dele, só leitura.
-- É o documento que já era feito para a conversa com a família.
do $$
declare t text;
begin
  foreach t in array array['avaliacoes','metas','torneios'] loop
    execute format('drop policy if exists "responsavel: do filho" on public.%I', t);
    execute format('create policy "responsavel: do filho" on public.%I'
      || ' for select to authenticated'
      || ' using (public.papel() = ''responsavel'' and data->>''atletaId'' = public.meu_atleta())', t);
  end loop;
end $$;

-- lança os próprios jogos. O papel entra na condição de propósito: sem ele,
-- QUALQUER conta autenticada — inclusive uma recém-criada, ainda sem convite —
-- conseguiria gravar jogos, bastando ser a autora da linha.
drop policy if exists "atleta: lancar jogo" on public.jogos;
create policy "atleta: lancar jogo" on public.jogos
  for insert to authenticated
  with check (public.papel() = 'atleta' and criado_por = auth.uid());

-- ...e edita só o que ele mesmo lançou (a marcação ponto a ponto ao vivo).
-- Não existe regra de exclusão para atleta: apagar jogo é só do treinador.
drop policy if exists "atleta: editar o proprio jogo" on public.jogos;
create policy "atleta: editar o proprio jogo" on public.jogos
  for update to authenticated
  using  (public.papel() = 'atleta' and criado_por = auth.uid())
  with check (public.papel() = 'atleta' and criado_por = auth.uid());


-- 3b) CONVITES: como nascem os usuários novos ------------------------
-- O treinador cria um convite com um código curto e (opcionalmente) o atleta
-- que a pessoa vai acompanhar. A pessoa se cadastra sozinha no app usando o
-- código — e é o resgate do código que dá o acesso, não o cadastro.
create table if not exists public.convites (
  codigo     text primary key,
  atleta_id  text,
  nome       text,
  email      text,
  papel      text not null default 'responsavel'
             check (papel in ('responsavel','atleta','treinador')),
  criado_por uuid default auth.uid() references auth.users(id) on delete set null,
  criado_em  timestamptz not null default now(),
  usado_em   timestamptz,
  usado_por  uuid references auth.users(id) on delete set null
);
alter table public.convites enable row level security;
grant select, insert, update, delete on public.convites to authenticated;
revoke all on public.convites from anon;

-- só o treinador enxerga e administra convites. Quem resgata não precisa ler
-- a tabela: quem lê é a função abaixo, em nome dele.
drop policy if exists "convites: treinador" on public.convites;
create policy "convites: treinador" on public.convites
  for all to authenticated
  using (public.papel() = 'treinador') with check (public.papel() = 'treinador');

-- Resgate. É "security definer" de propósito: sem isto, o próprio usuário
-- precisaria poder editar o seu papel — e aí qualquer um se promoveria a
-- treinador. Aqui ele não escolhe nada: o papel e o atleta vêm do convite.
create or replace function public.resgatar_convite(cod text, nome_pessoa text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare c public.convites;
begin
  if auth.uid() is null then
    raise exception 'precisa estar logado' using errcode = '42501';
  end if;
  select * into c from public.convites where upper(codigo) = upper(btrim(cod));
  if not found then
    raise exception 'convite nao encontrado' using errcode = '22023';
  end if;
  if c.usado_em is not null then
    raise exception 'convite ja utilizado' using errcode = '22023';
  end if;
  -- só quem ainda não tem acesso resgata. Sem isto, quem já entrou poderia
  -- usar um segundo código para trocar de atleta — ou virar treinador, se um
  -- código de treinador vazasse.
  if coalesce((select papel from public.perfis where id = auth.uid()), 'pendente') <> 'pendente' then
    raise exception 'este usuario ja tem acesso' using errcode = '22023';
  end if;

  insert into public.perfis (id, nome) values (auth.uid(), nullif(btrim(nome_pessoa),''))
    on conflict (id) do nothing;
  update public.perfis
     set papel = c.papel,
         atleta_id = c.atleta_id,
         nome = coalesce(nullif(btrim(nome_pessoa),''), nome)
   where id = auth.uid();
  update public.convites
     set usado_em = now(), usado_por = auth.uid()
   where codigo = c.codigo;

  return jsonb_build_object('papel', c.papel, 'atleta_id', c.atleta_id);
end $$;
grant execute on function public.resgatar_convite(text, text) to authenticated;

-- Convite sem atleta: a pessoa cadastra o filho no primeiro acesso. Também
-- security definer, para que ela não possa se vincular a um atleta alheio.
create or replace function public.cadastrar_meu_atleta(dados jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare novo text; meu_papel text;
begin
  if auth.uid() is null then
    raise exception 'precisa estar logado' using errcode = '42501';
  end if;
  select papel into meu_papel from public.perfis where id = auth.uid();
  if meu_papel is distinct from 'responsavel' then
    raise exception 'sem permissao' using errcode = '42501';
  end if;
  if (select atleta_id from public.perfis where id = auth.uid()) is not null then
    raise exception 'ja existe atleta vinculado' using errcode = '22023';
  end if;
  insert into public.atletas (data) values (dados) returning id into novo;
  update public.perfis set atleta_id = novo where id = auth.uid();
  return novo;
end $$;
grant execute on function public.cadastrar_meu_atleta(jsonb) to authenticated;


-- 4) ALTERAÇÃO PARCIAL DE UM DOCUMENTO --------------------------------
-- O app usa .update({campo:valor}) para mexer em um campo só (ex.: marcar
-- uma meta como cumprida). Isto faz a mesclagem dentro do banco, em uma
-- operação só. Roda com as permissões de quem chamou, então as regras
-- acima continuam valendo.
create or replace function public.doc_merge(tabela text, doc_id text, patch jsonb)
returns void language plpgsql security invoker set search_path = public as $$
begin
  if tabela not in ('atletas','avaliacoes','metas','torneios','jogos','relatorios') then
    raise exception 'tabela invalida: %', tabela using errcode = '22023';
  end if;
  execute format('update public.%I set data = data || $1 where id = $2', tabela)
    using patch, doc_id;
end $$;

grant execute on function public.doc_merge(text, text, jsonb) to authenticated;
grant execute on function public.papel() to authenticated;
grant execute on function public.meu_atleta() to authenticated;


-- 5) TEMPO REAL --------------------------------------------------------
-- Faz o técnico ver, do celular dele, o jogo que outra pessoa está marcando.
do $$
declare t text;
begin
  foreach t in array array['atletas','avaliacoes','metas','torneios','jogos','relatorios'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception
      when duplicate_object then null;
      when undefined_object then null;
    end;
  end loop;
end $$;


-- 6) PULSO: a tabelinha que impede o banco de hibernar ----------------
-- No plano gratuito, o Supabase pausa o projeto depois de ~7 dias sem uso.
-- O robô do GitHub (.github/workflows/manter-acordado.yml) lê esta tabela
-- uma vez por dia, e isso basta para o banco continuar de pé.
-- Ela guarda só um horário: nenhum dado do programa passa por aqui.
create table if not exists public.pulso (
  id        int primary key default 1 check (id = 1),
  visto_em  timestamptz not null default now()
);
insert into public.pulso (id) values (1) on conflict (id) do nothing;
alter table public.pulso enable row level security;

grant select on public.pulso to anon, authenticated;
drop policy if exists "pulso: leitura publica" on public.pulso;
create policy "pulso: leitura publica" on public.pulso
  for select to anon, authenticated using (true);


-- 7) O ÚLTIMO PASSO, QUE VOCÊ FAZ UMA VEZ SÓ --------------------------
-- Depois de criar o SEU usuário (Authentication > Users > Add user),
-- rode a linha abaixo trocando o e-mail — ela te promove a treinador.
-- Sem isso, todo mundo (inclusive você) entra como atleta.
--
--   update public.perfis set papel = 'treinador'
--    where id = (select id from auth.users where email = 'seu@email.com');
