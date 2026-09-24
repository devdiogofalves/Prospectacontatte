-- Backfill leads.atividade usando dados reais de CNPJ (atividade_principal)
-- Fonte: publica.cnpj.ws (Receita Federal). A trigger sync_atividade_to_lead
-- propaga empresas_enriquecidas.atividade_principal -> leads.atividade (canonizado
-- por atividade_por_padrao). telefone igual ao do lead evita duplicar lead no
-- trigger sync_insert_enriquecidos_to_lead.

INSERT INTO empresas_enriquecidas
  (lead_id, fonte, nome_empresa, telefone, cnpj, razao_social, nome_fantasia, atividade_principal, cnpj_validado, user_id)
VALUES
  ('6129d182-d19f-416b-9a47-830bc1701c73','cnpj_ws','SERVPOLI FACILITIES E SERVICOS LTDA','554131148559','08411757000180','SERVPOLI FACILITIES E SERVICOS LTDA','SERVPOLI FACILITIES E SERVICOS LTDA','Serviços combinados para apoio a edifícios, exceto condomínios prediais',true,'137fd3ed-4591-4abb-99a3-a091a085f7d5'),
  ('a6b8817d-5221-4475-bb87-60a56e3c5318','cnpj_ws','GRP LEAL COMERCIO E MANUTENCAO DE FERRAMENTAS LTDA','5541987761086','56184920000161','GRP LEAL COMERCIO E MANUTENCAO DE FERRAMENTAS LTDA','GRUPO LEAL','Manutenção e reparação de máquinas-ferramenta',true,'137fd3ed-4591-4abb-99a3-a091a085f7d5'),
  ('f4e5f9fb-d9e6-4d8e-8016-d9aa14b9400a','cnpj_ws','PATRICIA HARFF ESTETICA E BELEZA LTDA','554130883282','40594685000166','PATRICIA HARFF ESTETICA E BELEZA LTDA','CLINICA PATRICIA HARFF','Atividades de estética e outros serviços de cuidados com a beleza',true,'137fd3ed-4591-4abb-99a3-a091a085f7d5'),
  ('97451fd1-8ce4-44b2-9df3-a52b562b9df0','cnpj_ws','STUDIO W CABELEIREIROS LTDA','551130942640','01429920001164','STUDIO W CABELEIREIROS LTDA','RITU','Cabeleireiros, manicure e pedicure',true,'137fd3ed-4591-4abb-99a3-a091a085f7d5')
ON CONFLICT (cnpj, user_id) DO UPDATE
  SET atividade_principal = EXCLUDED.atividade_principal,
      lead_id             = EXCLUDED.lead_id,
      nome_empresa        = EXCLUDED.nome_empresa,
      razao_social        = EXCLUDED.razao_social,
      nome_fantasia       = EXCLUDED.nome_fantasia,
      telefone            = EXCLUDED.telefone,
      cnpj_validado       = true,
      updated_at          = now();

-- Backfill de segurança: recalcula leads.atividade nulos usando
-- inferir_atividade_empresa (len do CNPJ/empresas_enriquecidas + padrões de nome).
UPDATE leads
SET atividade = public.inferir_atividade_empresa(nome_empresa, NULL, cnpj, user_id)
WHERE atividade IS NULL OR btrim(atividade) = '';
