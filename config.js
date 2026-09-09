/* ---------------------------------------------------------------------
   Ligação com o banco do clube (Supabase).

   Enquanto estes dois campos estiverem vazios, o app roda em MODO LOCAL DE
   TESTE: os dados ficam salvos só no navegador de quem abriu, e ninguém vê o
   lançamento de ninguém. Preenchendo os dois, todo mundo passa a usar o mesmo
   banco, com entrada por e-mail e senha.

   O passo a passo para conseguir estes dois valores está em docs/SUPABASE.md.

   A "chave anon" é pública de propósito — ela só diz *qual* é o banco. Quem
   pode ver e gravar o quê é decidido dentro do banco (supabase/schema.sql),
   depois que a pessoa entra com e-mail e senha.
   --------------------------------------------------------------------- */
window.TCC_CONFIG = {
  SUPABASE_URL: "",
  SUPABASE_ANON_KEY: ""
};
