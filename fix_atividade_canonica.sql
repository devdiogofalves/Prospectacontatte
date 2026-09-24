-- Corrige inferir_atividade_empresa para NUNCA retornar a descrição bruta
-- de CNAE (ex.: "Atividades de organizações religiosas ou filosóficas") em
-- leads.atividade. O campo atividade só aceita categorias canônicas
-- (Saúde/Cuidados Estéticos, Alimentação/Restaurantes, ...) ou NULL.
-- Precisão > cobertura: se nome E CNAE não forem classificáveis, retorna NULL
-- em vez de poluir o campo com texto não canônico.
--
-- Aplica-se tanto ao backfill quanto aos triggers:
--   trg_leads_atividade        -> set_lead_atividade()
--   trg_empresa_atividade_to_lead -> sync_atividade_to_lead()

-- Remove qualquer sobrecarga de 4 args (causa da ambiguidade "is not unique").
DROP FUNCTION IF EXISTS public.inferir_atividade_empresa(text, text, text, uuid);

CREATE OR REPLACE FUNCTION public.inferir_atividade_empresa(
  p_nome text,
  p_atividade_principal text DEFAULT NULL::text,
  p_cnpj text DEFAULT NULL::text,
  p_user_id uuid DEFAULT NULL::uuid,
  p_especialidades text DEFAULT NULL::text,
  p_segmento text DEFAULT NULL::text
)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_ativ text;
  v_cand text;
  v_cnpj_norm text;
BEGIN
  v_cnpj_norm := regexp_replace(coalesce(p_cnpj, ''), '\D', '', 'g');

  -- (A) sem atividade explícita: tenta achar em empresas_enriquecidas
  --     (por CNPJ normalizado ou por nome) do mesmo usuário.
  IF (p_atividade_principal IS NULL OR btrim(p_atividade_principal) = '') AND p_user_id IS NOT NULL THEN
    SELECT ee.atividade_principal INTO v_ativ
    FROM empresas_enriquecidas ee
    LEFT JOIN leads l ON l.id = ee.lead_id
    WHERE (l.user_id = p_user_id OR ee.lead_id IS NULL)
      AND (
        (v_cnpj_norm <> '' AND regexp_replace(ee.cnpj, '\D', '', 'g') = v_cnpj_norm)
        OR public.norm_text(ee.nome_empresa) = public.norm_text(p_nome)
      )
    ORDER BY (ee.atividade_principal IS NOT NULL AND ee.atividade_principal <> '') DESC NULLS LAST
    LIMIT 1;
    IF v_ativ IS NOT NULL THEN
      p_atividade_principal := v_ativ;
    END IF;
  END IF;

  -- (B) padrão por nome da empresa (rótulo canônico) — prioridade máxima
  v_cand := public.atividade_por_padrao(p_nome);
  IF v_cand IS NOT NULL THEN
    RETURN v_cand;
  END IF;

  -- (C) padrão sobre a atividade principal (CNAE/receita) — canônico.
  --     Só retorna categoria canônica. Se a CNAE não for classificável,
  --     retorna NULL (precisão > cobertura): não polui leads.atividade
  --     com descrições brutas de CNAE.
  IF p_atividade_principal IS NOT NULL AND btrim(p_atividade_principal) <> '' THEN
    v_cand := public.atividade_por_padrao(p_atividade_principal);
    IF v_cand IS NOT NULL THEN
      RETURN v_cand;
    END IF;
  END IF;

  RETURN NULL;
END;
$function$;

-- Backfill de correção: re-deriva apenas os leads cuja atividade NÃO é uma
-- categoria canônica (restos de CNAE bruto). Passa NULL para o CNAE principal
-- para usar APENAS o padrão de nome (alta precisão); leads sem sinal de nome
-- ficam NULL (em vez de lixo).
UPDATE leads l
SET atividade = public.inferir_atividade_empresa(l.nome_empresa, NULL, l.cnpj, l.user_id)
WHERE l.atividade IS NOT NULL
  AND btrim(l.atividade) <> ''
  AND l.atividade NOT IN (
    'Saúde/Cuidados Estéticos',
    'Energia/Combustíveis',
    'Alimentação/Restaurantes',
    'Varejo/Comércio',
    'Construção/Serviços',
    'Serviços Gerais/Limpeza',
    'Tecnologia/Software',
    'Marketing/Publicidade',
    'Educação',
    'Imobiliário',
    'Advocacia/Jurídico',
    'Contabilidade/Financeiro',
    'Transporte/Logística',
    'Automotivo',
    'Pet Shop/Veterinária',
    'Agronegócio',
    'Indústria',
    'Segurança',
    'Hotelaria/Turismo',
    'Eventos/Celebrações',
    'Fitness/Academia'
  );

-- Verificação 1: nenhum valor não-canônico restante
SELECT 'NAO_CANONICOS' AS info, COUNT(*)::text AS qtd
FROM leads
WHERE atividade IS NOT NULL
  AND btrim(atividade) <> ''
  AND atividade NOT IN (
    'Saúde/Cuidados Estéticos','Energia/Combustíveis','Alimentação/Restaurantes',
    'Varejo/Comércio','Construção/Serviços','Serviços Gerais/Limpeza','Tecnologia/Software',
    'Marketing/Publicidade','Educação','Imobiliário','Advocacia/Jurídico','Contabilidade/Financeiro',
    'Transporte/Logística','Automotivo','Pet Shop/Veterinária','Agronegócio','Indústria','Segurança',
    'Hotelaria/Turismo','Eventos/Celebrações','Fitness/Academia'
  );

-- Verificação 2: lead de referência
SELECT 'REFERENCIA' AS info, nome_empresa, atividade
FROM leads
WHERE nome_empresa ILIKE '%gabriela werneck%';

-- Verificação 3: resumo geral
SELECT
  (SELECT COUNT(*) FROM leads) AS total_leads,
  (SELECT COUNT(*) FROM leads WHERE atividade IS NULL OR btrim(atividade)='') AS nulos,
  (SELECT COUNT(*) FROM leads WHERE atividade IS NOT NULL AND btrim(atividade)<>'') AS preenchidos;
