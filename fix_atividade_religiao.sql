-- Remove a branch não-canônica 'Religião/Espiritualidade' de
-- atividade_por_padrao. O contrato canônico (fix_atividade_canonica.sql /
-- fix_lead_atividade.sql) admite SOMENTE as 21 categorias canônicas ou NULL
-- ("precisão > cobertura": não polui leads.atividade com texto não canônico).
-- A branch religiosa fazia o lead "Velho Madalosso." (CNAE "Atividades de
-- organizações religiosas ou filosóficas") ficar preso num valor fora da
-- lista canônica, impossibilitando o backfill de normalizá-lo.
-- Mantém TODOS os demais padrões da versão em produção (wellness, health,
-- condominio, tech, etc.).
CREATE OR REPLACE FUNCTION public.atividade_por_padrao(s text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  n text := public.norm_text(s);
BEGIN
  -- Saúde/Cuidados Estéticos
  IF n ~ '\m(clinica|clinico|clinic|consultorio|saude|estetica|estetico|aesthetic|esthetic|odont|odontologica|dentista|dentario|medic|medical|médica|medico|medicina|ambulatorial|hospital|hospitalar|spa|bemestar|salao|cabeleireir|cabelo|manicure|pedicure|barbearia|massagem|bioestetica|ortodontia|pediatra|cosmetic|laboratorio|beleza|beauty|salon|hair|hairdress|coiffeur|facial|loira|dra|acupuntura|quiropraxia|harmonizacao|botox|diagnostico|especialidade|wellness|wellbeing|health|care|vacinação|vacinacao|imunização|imunizacao|tomografia)\M' OR n ~ '\m(ginecolog|cardiolog|dermatolog|odontolog|psicolog|psiqui|ortoped|oftalmolog|fonoaudiolog|nutricion|terapia|fisio|optica|podolog)' THEN
    RETURN 'Saúde/Cuidados Estéticos';
  -- Energia/Combustíveis: gás/combustível (inclui marcas embutidas), energia, postos de combustível.
  ELSIF n ~ '\m(energia|energias|combustivel|combustiveis|gasolina|diesel|etanol|glp|gnv|petroleo|petroleos|lubrificante|lubrificantes|biodiesel|biocombustivel|biocombustiveis|querosene|solar|fotovoltaica|eolica|gas\M|gaz\M|posto de (combustivel|gasolina|gas))\M'
        OR ((n ~ 'gas' OR n ~ 'gaz') AND n !~ 'gastronom') THEN
    RETURN 'Energia/Combustíveis';
  ELSIF n ~ '\m(braseiro|assador|steakhouse|grill|parrilha|parrilla|barbecue|bbq|churrascaria|churrasco|restaurante|restaurantes|lanchonete|lanchon|lanchonetes|pizzaria|cafeteria|cafe|padaria|confeitaria|confeit|burger|hamburguer|hamburgueria|mercado|supermercado|acougue|peixaria|food|comida|refeicao|doceria|sorveteria|emporia|emporio|mercearia|bar|barzinh|alimento|alimentos|pizza|pizzeria|ristorante|trattoria|osteria|resto|brasa|bife|mamma|cantina|degust|sushi|sushis|japa|temakeria|temaki|cervejaria|choperia|parmegiana|parmesa|margherita|boteco|pastel|pastelaria|acai|açaí|crepe|creperia|frutaria|alimentacao|gourmet|gastro|comidas|refeicoes|fornecimento)\M'
        OR n LIKE '%foods%' OR n LIKE '%nectar%' OR n LIKE '%bebida%' THEN
    RETURN 'Alimentação/Restaurantes';
  ELSIF n ~ '\m(loja|magazine|boutique|vestuario|roupa|calcados|sapato|departamento|varejo|shopping|mercadinh|empory|comercio|ecommerce|e-commerce|venda)\M' THEN
    RETURN 'Varejo/Comércio';
  ELSIF n ~ '\m(construcao|construtora|engenharia|reforma|eletrica|hidraulica|pedreiro|marcenaria|pintura|moveis|movel|serralheria|alvenaria|telhado|pavimentacao|climatizacao|manutencao|reparacao|conserto|maquina|ferramenta|instalacao|montagem)\M'
        OR n LIKE '%maquinas%' OR n LIKE '%equipamentos%' THEN
    RETURN 'Construção/Serviços';
  ELSIF n ~ '\m(limpeza|asseio|conservacao|portaria|facilities|terceirizad|zeladoria|predial|servic|condominio|condomínio|condominios|condomínios|edificios|edifícios|residuos|resíduos)\M'
        OR n LIKE '%bpo%' OR n LIKE '%outsourc%' THEN
    RETURN 'Serviços Gerais/Limpeza';
  ELSIF n ~ '\m(tecnologia|tech|tecnologic|software|sistema|informatica|desenvolvimento|digital|dados|cloud|computador|marketingdigital|aplicativo|solu|web|app|ti)\M'
        OR n LIKE '%data%' OR n LIKE '%tech%' OR n LIKE '%analytics%' OR n LIKE '%inteligencia%' OR n LIKE '%automacao%' THEN
    RETURN 'Tecnologia/Software';
  ELSIF n ~ '\m(agencia|marketing|publicidade|propaganda|midia|media|publicitari|branding|comunicacao|socialmedia|influencer|fotograf|livr|editora|edicao|publicacao|impressao|promoção|promocao)\M'
        OR n LIKE '%clique%' OR n LIKE '%influenciador%' OR n LIKE '%fotograf%' THEN
    RETURN 'Marketing/Publicidade';
  ELSIF n ~ '\m(escola|curso|ensino|educacao|faculdade|universidade|treinamento|idioma|professor|professora|colegio|creche|bercario|mentoria|aula)\M' THEN
    RETURN 'Educação';
  ELSIF n ~ '\m(imobiliaria|imovel|imoveis|corretor|loteamento|incorporadora)\M' THEN
    RETURN 'Imobiliário';
  ELSIF n ~ '\m(advocacia|advogado|juridico|juridica)\M' THEN
    RETURN 'Advocacia/Jurídico';
  ELSIF n ~ '\m(contabilidade|contador|financeiro|auditoria)\M' THEN
    RETURN 'Contabilidade/Financeiro';
  ELSIF n ~ '\m(transporte|logistica|frete|entrega|mudanca|correio)\M' OR n LIKE '%delivery%' THEN
    RETURN 'Transporte/Logística';
  ELSIF n ~ '\m(automovel|automotivo|autocenter|autopeca|oficina|mecanica|veiculo|lavagem|esteticaautomotiva)\M' THEN
    RETURN 'Automotivo';
  ELSIF n ~ '\m(pet\M|petshop|veterinario|veterinaria|tosa|banhoetosa)\M' THEN
    RETURN 'Pet Shop/Veterinária';
  ELSIF n ~ '\m(agro|fazenda|rural|agronegocio)\M' OR n LIKE '%fertil%' OR n LIKE '%agroquimica%' THEN
    RETURN 'Agronegócio';
  ELSIF n ~ '\m(industria|fabricacao|fabrica|manufatura)\M' THEN
    RETURN 'Indústria';
  ELSIF n ~ '\m(seguranca|vigilancia|monitoramento|blindagem|portariaarmada)\M' THEN
    RETURN 'Segurança';
  ELSIF n ~ '\m(hotel|hoteis|motel|moteis|hostel|hosteis|pousada|turismo|viagem|travel|resort|resorts|inn|flat)\M' THEN
    RETURN 'Hotelaria/Turismo';
  ELSIF n ~ '\m(evento|festa|buffet|ceremonial|decoracao|show)\M' OR n LIKE '%producao%' OR n LIKE '%producoes%' THEN
    RETURN 'Eventos/Celebrações';
  ELSIF n ~ '\m(academia|fitness|crossfit|musculacao|pilates|funcional)\M' THEN
    RETURN 'Fitness/Academia';
  ELSIF n ~ '\m(consultoria|mao de obra|agenciamento|recursos humanos|rh)\M' THEN
    RETURN 'Serviços Gerais/Limpeza';
  END IF;
  RETURN NULL;
END;
$function$;

-- Backfill: re-deriva SOMENTE leads cuja atividade NÃO é canônica.
-- Como a branch religiosa foi removida, "Velho Madalosso." (CNAE religioso
-- sem padrão canônico) passa a NULL — em vez de valor não canônico.
UPDATE leads l
SET atividade = public.inferir_atividade_empresa(l.nome_empresa, NULL, l.cnpj, l.user_id)
WHERE l.atividade IS NOT NULL
  AND btrim(l.atividade) <> ''
  AND l.atividade NOT IN (
    'Saúde/Cuidados Estéticos','Energia/Combustíveis','Alimentação/Restaurantes',
    'Varejo/Comércio','Construção/Serviços','Serviços Gerais/Limpeza','Tecnologia/Software',
    'Marketing/Publicidade','Educação','Imobiliário','Advocacia/Jurídico','Contabilidade/Financeiro',
    'Transporte/Logística','Automotivo','Pet Shop/Veterinária','Agronegócio','Indústria','Segurança',
    'Hotelaria/Turismo','Eventos/Celebrações','Fitness/Academia'
  );

-- Verificação 1: anchor lead (deve ser Saúde/Cuidados Estéticos)
SELECT 'ANCHOR' AS info, nome_empresa, atividade
FROM leads
WHERE nome_empresa ILIKE '%gabriela werneck%';

-- Verificação 2: nenhum valor não-canônico restante
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

-- Verificação 3: resumo geral
SELECT
  (SELECT COUNT(*) FROM leads) AS total_leads,
  (SELECT COUNT(*) FROM leads WHERE atividade IS NULL OR btrim(atividade)='') AS nulos,
  (SELECT COUNT(*) FROM leads WHERE atividade IS NOT NULL AND btrim(atividade)<>'') AS preenchidos;
