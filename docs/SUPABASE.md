# Ligar o banco compartilhado (Supabase) — passo a passo

> Guia do **Ponto a Ponto**.

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
window.APP_CONFIG = {
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

## Passo 5 — Ligar o cadastro por convite

O app cria os usuários sozinho, por **código de convite**. Para isso o Supabase
precisa aceitar auto-cadastro — e duas configurações precisam estar assim:

1. **Authentication** → **Sign In / Providers** → **Email**
2. **Ligue** *Allow new users to sign up*
3. **Desligue** *Confirm email* — senão cada pessoa teria de esperar um e-mail
   de confirmação, e o envio gratuito do Supabase é limitado a poucos por hora
4. **Save**

> **"Mas assim qualquer um cria conta!"** Cria — e não vê **nada**. Conta nova
> nasce com o papel **pendente**, que não enxerga uma linha sequer do banco.
> Quem dá o acesso é o código do convite, e o código diz qual é o papel e qual
> é o atleta. Isso é decidido dentro do banco, não na tela: nem o navegador nem
> a pessoa conseguem mudar o próprio papel.

## Passo 6 — Convidar as pessoas (tudo pelo app)

Na aba **Acessos** (só você a enxerga), toque em **+ Convidar**:

| Campo | O que faz |
| --- | --- |
| **Quem é a pessoa** | Responsável (vê só o atleta dela), Atleta, ou Treinador (acesso total) |
| **Atleta que ela vai acompanhar** | Escolha um da lista — ou deixe *"ela mesma cadastra"*, e ela cadastra o filho no primeiro acesso |
| **Nome / e-mail** | Só para você lembrar de quem é o convite |

Sai um código de 6 letras (ex.: `K7R2QM`) e a mensagem pronta vai para a área de
transferência — é só colar no WhatsApp. A pessoa abre o link, toca em
**"Primeiro acesso? Tenho um código de convite"**, digita o código e escolhe a
própria senha.

Cada código serve **uma vez só**, e quem já tem acesso não consegue usar outro.

Na mesma aba você vê quem já entrou, troca o papel de alguém, troca o atleta de
um responsável, ou tira o acesso. Para apagar a conta de vez (e liberar o
e-mail), aí sim é pelo painel: **Authentication → Users → Delete user**.

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
| `pulso` | só um horário, usado pelo robô que impede o banco de hibernar |
| `convites` | os códigos de convite e o que cada um libera |

Cada linha guarda um documento em JSON na coluna `data`. Você pode olhar tudo
pelo **Table Editor** do Supabase, e exportar em CSV quando quiser.

## Quem pode o quê

| | Treinador | Atleta | Responsável | Pendente |
| --- | --- | --- | --- | --- |
| Elenco (nomes dos atletas) | tudo | vê todos | só o próprio filho | nada |
| Jogos | tudo | vê todos; lança e edita os seus | só os do filho, sem editar | nada |
| Avaliações, Metas, Torneios | tudo | — | só as do filho, sem editar | nada |
| Relatório do Programa | tudo | — | — | nada |
| Acessos e convites | tudo | — | — | nada |

Isso é garantido pelo **banco**, não pela tela: mesmo que alguém tente burlar o
app, o Postgres recusa. As regras estão no fim do `supabase/schema.sql`.

---

## O banco hiberna? (e o robô que impede isso)

No plano gratuito, o Supabase **pausa o projeto depois de ~7 dias sem nenhum
acesso**. Quando isso acontece, o sistema abre com erro de banco até alguém
retomar — e os dados continuam seguros o tempo todo, nada se perde.

**Para retomar na mão:** abra <https://supabase.com/dashboard>, entre no projeto
e clique em **Resume project**. Leva 1 a 2 minutos. (Se o Chrome estiver
traduzindo a página, esse botão aparece como *"Projeto de currículo"* — é um erro
do tradutor: *resume* aqui é **retomar**, não currículo. É o botão certo.)

**Para não precisar fazer isso:** já existe um robô no repositório,
[`.github/workflows/manter-acordado.yml`](../.github/workflows/manter-acordado.yml),
que consulta o banco todo dia às 10h23 de Brasília. Um acesso por dia basta para
o projeto nunca hibernar. Ele não usa senha — lê a URL e a chave publicável do
próprio `config.js` e consulta a tabela `pulso`, que guarda só um horário.

Para ver se está rodando: aba **Actions** do repositório → *Manter o banco
acordado*. Se alguma execução falhar, o GitHub te manda um e-mail.

> ⚠️ **Um limite do GitHub:** se o repositório passar **60 dias sem nenhuma
> alteração**, ele desliga sozinho as tarefas agendadas (e avisa por e-mail).
> Aí basta reativar na aba Actions, ou clicar em *Run workflow* uma vez.

## A bolinha ao lado do título

No topo do app, ao lado de "Ponto a Ponto", há uma bolinha:
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
| "E-mail ou senha incorretos" | Confira o e-mail. Quem **lembra** a senha troca sozinho no app (botão **conta**, no topo). Quem **esqueceu** precisa de você: Authentication → Users → três pontinhos → *Reset password*. |
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
