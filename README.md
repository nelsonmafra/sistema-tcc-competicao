# Ponto a Ponto

Sistema de acompanhamento de atletas de tênis de competição.

O nome é o que ele faz: o jogo é marcado ponto a ponto da arquibancada, e é
daí que sai tudo — o placar, a leitura da pressão, a conversa do intervalo e o
dossiê do atleta.
Uma página só (`index.html`), sem instalação: abre no celular na beira da quadra
e no computador do treinador.

## Módulos

| Módulo | O que faz |
| --- | --- |
| **Painel** | KPIs do trimestre (atletas ativos, avaliações feitas, metas cumpridas, torneios, jogos V–D) e um cartão por atleta com a média das 5 dimensões e a variação contra o trimestre anterior. |
| **Atletas** | Cadastro: nome, nascimento, categoria, bola/etapa (vermelha → amarela), grupo de treino e situação (ativo/inativo). |
| **Avaliações** | Uma avaliação por atleta por trimestre: notas 1–5 em Técnica, Tática, Física, Atitude e Competitividade, frequência, os 5 critérios de promoção, revisão das metas do PDI, parecer (manter / observar / **promovível**) e devolutiva à família. |
| **Metas (PDI)** | 3 a 5 metas de processo por atleta, com biblioteca de metas prontas por área (saque, devolução, fundo, rede, tática, física, mental), indicador, prazo e status. |
| **Torneios** | Uma análise por atleta por torneio, preenchida pelo treinador do rodízio em até 48h: 7 perguntas fechadas + anotações. Os jogos já lançados do torneio entram sozinhos. |
| **Jogos** | Cadastro com adversário e clube, categoria, local, torneio, rodada, piso e nível do torneio (do amistoso ao Grand Slam). **▶ Ao vivo** — marcação ponto a ponto da arquibancada, com placar (games, tiebreak, match tiebreak, no-ad) calculado sozinho e classificação de cada ponto (ace, winner, erro forçado, erro não forçado, dupla falta). **👁 Acompanhar** — qualquer pessoa logada assiste à partida ao vivo, de outro aparelho, sem nenhum botão que grave; inclui **placar grande** em tela cheia, para tablet ou TV na sede. **📊 Resumo** — a qualquer momento da partida: números, desempenho sob pressão e uma leitura em linguagem de treinador (saque, devolução, break points, winners × erros, momento) com o que fazer a respeito. Na **virada de set** e no fim do jogo essa tela aparece sozinha, em tamanho de TV. **+ Resultado** — registro rápido de jogo encerrado. **⇪ Importar** — planilha `.xlsx`/`.csv` ou colagem do Excel. |
| **Relatórios** | *Trimestral do Programa* (documento do comitê, preenchido automaticamente + campos de destaques, pendências e decisões), *Dossiê do Atleta* (evolução histórica, metas, competição, leitura automática) e *Relatório da partida* (ponto a ponto, desempenho sob pressão, score worm, pressão tática). Todos têm **🖨 imprimir / PDF** — no relatório da partida o PDF sai com **todos os sets**, um por página, mesmo que a tela mostre um de cada vez, e sempre em fundo branco ainda que o aparelho esteja no modo escuro. |

O trimestre exibido é escolhido pelas setas `‹ ›` no topo — todo o sistema segue esse recorte.

## Papéis

- **Treinador** — acesso total a todos os módulos.
- **Atleta** — vê apenas a aba Jogos: lança as próprias partidas e abre os relatórios de partida (📊).

O botão **conta**, no topo, mostra com quem você está conectado, troca a sua
senha e sai da conta.

## Banco de dados

O app fala com o banco por uma interface única — `collection().add / doc().set /
update / delete / onSnapshot` — com três implementações escolhidas na abertura:

1. **Supabase** (Postgres gratuito) — o banco compartilhado do clube. Liga
   sozinho quando o [`config.js`](config.js) está preenchido: aí o app pede
   e-mail e senha, e o próprio banco decide quem pode o quê. Passo a passo para
   ligar: [`docs/SUPABASE.md`](docs/SUPABASE.md). Estrutura e regras de acesso:
   [`supabase/schema.sql`](supabase/schema.sql).
2. **`claude.use('db')`** — quando a página é aberta como artifact no claude.ai.
3. **`localStorage`** — modo local de teste: sem configuração nenhuma o app
   abre e funciona, mas os dados ficam só no navegador de quem abriu.

No plano gratuito o Supabase pausa o projeto depois de ~7 dias sem acesso. O
robô [`manter-acordado.yml`](.github/workflows/manter-acordado.yml) consulta o
banco uma vez por dia e evita isso — e manda e-mail se algo estiver fora do ar.
