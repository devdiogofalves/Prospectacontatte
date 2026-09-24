-- View leads_unified: banco mestre multicanal para /meus-leads
-- Unifica as tabelas de lead em um schema comum com coluna `source`.
-- Inclui apenas tabelas que possuem user_id direto (leads, instagram_hashtag_leads).
-- LinkedIn/Instagram contacts e empresas_enriquecidas não têm user_id direto
-- (relacionam via unipile_account_id / lead_id) — fora do escopo inicial.
CREATE OR REPLACE VIEW leads_unified AS
SELECT
  id,
  user_id,
  'maps'::text AS source,
  nome_empresa,
  nome_contato,
  telefone,
  email,
  cargo,
  cidade,
  NULL::text AS uf,
  segmento,
  created_at
FROM leads
WHERE user_id IS NOT NULL

UNION ALL

SELECT
  id,
  user_id,
  'instagram_hashtag'::text AS source,
  username AS nome_empresa,
  full_name AS nome_contato,
  NULL::text AS telefone,
  NULL::text AS email,
  NULL::text AS cargo,
  NULL::text AS cidade,
  NULL::text AS uf,
  hashtag AS segmento,
  created_at
FROM instagram_hashtag_leads
WHERE user_id IS NOT NULL;
