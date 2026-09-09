# Ligar o banco compartilhado (Supabase) — passo a passo

Hoje, aberto pelo GitHub Pages, o sistema roda em **modo local de teste**: o que
você lança fica salvo só no navegador do seu aparelho. Ninguém mais vê.

Este guia liga o **banco de verdade**: um Postgres gratuito no Supabase, onde
treinadores e atletas usam os mesmos dados, cada um com o seu e-mail e senha.

O plano gratuito do Supabase é folgado para o programa (500 MB de banco e
50.000 usuários por mês). Não pede cartão.

> Faça um passo por vez. Cada passo termina com algo pronto.

---

## Passo 1 — Criar a conta e o projeto

1. Abra <https://supabase.com> e clique em **Start your project**.
2. Entre com a sua conta do GitHub (a mais rápida) ou com e-mail e senha.
3. Clique em **New project** e preencha:
   - **Name**: `tcc-competicao`
   - **Database Password**: clique em *Generate a password* e **guarde essa
     senha** num lugar seguro. É a senha do banco, não a sua de login — você
     provavelmente nunca vai precisar dela, mas não dá para recuperar depois.
   - **Region**: `South America (São Paulo)`
4. Clique em **Create new project** e espere uns 2 minutos.

---

## Passo 2 — Criar as tabelas

1. No menu da esquerda, clique em **SQL Editor**.
2. Clique em **New query**.
3. Abra o arquivo [`supabase/schema.sql`](../supabase/schema.sql) deste
   repositório, copie **tudo** e cole na janela do SQL Editor.
4. Clique em **Run** (ou `Ctrl+Enter`).

Deve aparecer *Success. No rows returned* — é isso mesmo, ele criou as tabelas
e as regras de acesso.

---

## Passo 3 — Criar o seu usuário e virar treinador

1. Menu da esquerda: **Authentication** → **Users** → **Add user** →
   **Create new user**.
2. Preencha o seu e-mail e uma senha, **marque `Auto Confirm User`** e
   confirme.
3. Volte ao **SQL Editor**, cole a linha abaixo trocando o e-mail pelo seu, e
   clique em **Run**:

   ```sql
   update public.perfis set papel = 'treinador'
    where id = (select id from auth.users where email = 'seu@email.com');
   ```

Pronto: você é treinador e tem acesso total. **Todo usuário novo entra como
atleta** — é por isso que este passo existe.

---

## Passo 4 — Copiar os dois endereços do banco

1. Menu da esquerda: **Project Settings** (a engrenagem) → **API**.
2. Anote os dois valores:
   - **Project URL** — algo como `https://abcdefghijk.supabase.co`
   - **anon public** (em *Project API keys*) — uma chave longa

Me mande esses dois valores e eu preencho o `config.js` para você. Se preferir
fazer sozinho: abra o `config.js` aqui no GitHub, clique no lápis ✏️, cole os
dois valores entre as aspas e clique em **Commit changes**.

```js
window.TCC_CONFIG = {
  SUPABASE_URL: "https://abcdefghijk.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."
};
```

> **A chave `anon` é pública de propósito** e pode ficar aqui no repositório.
> Ela só diz *qual* é o banco. Quem pode ver e gravar o quê é decidido dentro
> do banco, depois que a pessoa entra com e-mail e senha. A chave
> `service_role`, essa sim, **nunca** pode ser colocada aqui.

Um minuto depois de salvar, o site já pede e-mail e senha para entrar.

---

## Passo 5 — Dar acesso ao resto da equipe

Para cada treinador ou atleta, repita o **Passo 3.1** (Authentication → Users →
Add user, com `Auto Confirm User` marcado) e passe o e-mail e a senha para a
pessoa.

- **Atleta**: não precisa fazer mais nada. Ele entra vendo só a aba **Jogos** —
  lança as partidas dele e abre os relatórios de partida (📊).
- **Treinador**: rode de novo o SQL do Passo 3.3 com o e-mail dele.

Para tirar o acesso de alguém: **Authentication** → **Users** → os três
pontinhos ao lado do nome → **Delete user**.

---

## Passo 6 (recomendado) — Fechar o cadastro público

Para que ninguém crie conta sozinho:

**Authentication** → **Sign In / Providers** → **Email** → desligue
**Allow new users to sign up** → **Save**.

A partir daí só entra quem você criou na mão.

---

## O que fica onde

| Tabela no Supabase | Módulo do app |
| --- | --- |
| `perfis` | quem é treinador e quem é atleta |
| `atletas` | Atletas |
| `avaliacoes` | Avaliações trimestrais |
| `metas` | Metas (PDI) |
| `torneios` | Análises de torneio |
| `jogos` | Jogos, inclusive a marcação ponto a ponto |
| `relatorios` | textos do Relatório Trimestral do Programa |

Cada linha guarda um documento em JSON na coluna `data`. Você pode olhar tudo
pelo **Table Editor** do Supabase, e exportar em CSV quando quiser.

## Quem pode o quê

| | Treinador | Atleta |
| --- | --- | --- |
| Atletas, Avaliações, Metas, Torneios, Relatórios | ver e editar | — |
| Elenco (nomes dos atletas) | ver e editar | ver |
| Jogos | ver, editar e apagar todos | ver todos; lançar e editar só os seus |

Isso é garantido pelo **banco**, não pela tela: mesmo que alguém tente burlar o
app, o Postgres recusa. As regras estão no fim do `supabase/schema.sql`.

---

## A bolinha ao lado do título

No topo do app, ao lado de "TCC Competição", há uma bolinha:
**verde** = conectado ao banco, **amarela** = não conectado.

**Toque nela** para abrir o *Diagnóstico do banco*. Ele testa, em ordem:
configuração, biblioteca, sua sessão, o seu papel (treinador/atleta), a leitura
de cada uma das 6 tabelas, uma gravação de teste e o tempo real — e mostra em
português o que passou (✓) e o que falhou (✕), com o código do erro.

Quando algo der errado, é daí que sai a resposta: toque em **copiar** e mande o
texto. Não precisa entender o conteúdo.

## Se der problema

| O que aparece | O que fazer |
| --- | --- |
| "E-mail ou senha incorretos" | Confira o e-mail. Para trocar a senha: Authentication → Users → três pontinhos → *Reset password*. |
| "E-mail ainda não confirmado" | O usuário foi criado sem `Auto Confirm User`. Apague e crie de novo com a opção marcada. |
| "Seu perfil não tem permissão para esta ação" | A pessoa está como atleta. Rode o SQL do Passo 3.3 com o e-mail dela. |
| A tela de login não aparece | O `config.js` está vazio ou com um valor errado. Confira se a URL começa com `https://` e se a chave é a **anon**/publishable, não a `service_role`. |
| "não consegui ler o seu perfil" e você entra como atleta | Falta permissão na tabela `perfis`. Cole o `supabase/schema.sql` de novo no SQL Editor e rode — ele pode ser executado quantas vezes for preciso. |
| `42501 permission denied` em qualquer linha do diagnóstico | Mesma coisa: rode o `supabase/schema.sql` de novo. |
| Some tudo depois de trocar de aparelho | Você ainda está em modo local de teste — os dados do teste ficam só no navegador antigo e não sobem para o banco. |

## E os dados que eu já lancei no modo de teste?

Ficam no navegador onde foram lançados e **não** migram sozinhos. Se forem
poucos, o caminho mais rápido é relançar. Se forem muitos jogos, use a
**⇪ importar** da aba Jogos com uma planilha.
