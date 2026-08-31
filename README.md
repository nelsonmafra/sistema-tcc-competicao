# Sistema TCC Competição

Aplicativo do **Programa de Tênis de Competição do Tênis Clube de Campinas**.
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
| **Jogos** | **▶ Ao vivo** — marcação ponto a ponto da arquibancada, com placar (games, tiebreak, match tiebreak, no-ad) calculado sozinho e classificação de cada ponto (ace, winner, erro forçado, erro não forçado, dupla falta). **+ Resultado** — registro rápido de jogo encerrado. **⇪ Importar** — planilha `.xlsx`/`.csv` ou colagem do Excel. |
| **Relatórios** | *Trimestral do Programa* (documento do comitê, preenchido automaticamente + campos de destaques, pendências e decisões), *Dossiê do Atleta* (evolução histórica, metas, competição, leitura automática) e *Relatório da partida* (ponto a ponto, desempenho sob pressão, score worm, pressão tática). Todos imprimem em PDF pelo navegador. |

O trimestre exibido é escolhido pelas setas `‹ ›` no topo — todo o sistema segue esse recorte.

## Papéis

- **Treinador** — acesso total a todos os módulos.
- **Atleta** — vê apenas a aba Jogos: lança as próprias partidas e abre os relatórios de partida (📊).

## Banco de dados

Sem configuração, o app roda em **modo local de teste**: os dados ficam salvos
só no navegador de quem abriu. Para o banco compartilhado da equipe, veja
[`docs/SUPABASE.md`](docs/SUPABASE.md).

## Trio técnico

Johan "Yuki" Wachtmeister · Sergio Urbano Luiz · João Guilherme Chiminazzo
