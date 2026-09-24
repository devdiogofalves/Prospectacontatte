-- atividade_por_padrao: canonicaliza um texto (nome da empresa OU
-- atividade_principal/CNAE de empresas_enriquecidas) em uma categoria de
-- atividade de lead. Usada por inferir_atividade_empresa (backfill + triggers
-- set_lead_atividade / sync_atividade_to_lead).
--
-- Categorias canônicas (devem bater com a lista do backfill em
-- fix_lead_atividade.sql):
--   Saúde/Cuidados Estéticos, Energia/Combustíveis, Alimentação/Restaurantes,
--   Varejo/Comércio, Construção/Serviços, Serviços Gerais/Limpeza,
--   Tecnologia/Software, Marketing/Publicidade, Educação, Imobiliário,
--   Advocacia/Jurídico, Contabilidade/Financeiro, Transporte/Logística,
--   Automotivo, Pet Shop/Veterinária, Agronegócio, Indústria, Segurança,
--   Hotelaria/Turismo, Eventos/Celebrações, Fitness/Academia.
--
-- Manutenção (2026-08-28): adicionada categoria Energia/Combustíveis
-- (gas/energia/combustível) COM PRIORIDADE antes de Construção, para não
-- confundir distribuidoras de gás com manutenção; e ampliados os padrões de
-- Construção (manutenção/máquinas/instalação) e Marketing (fotografia/livros/
-- edição) para cobrir descrições CNAE brutas comuns.

CREATE OR REPLACE FUNCTION public.atividade_por_padrao(s text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  n text := public.norm_text(s);
BEGIN
  -- Saúde/Cuidados Estéticos
  IF n ~ '\m(clinica|clinico|consultorio|saude|estetica|estetico|dermatolog|odontolog|odont|dentista|dentario|medic|hospital|fisioterapia|fisio|nutri|psicolog|psiqui|spa|bemestar|salao|cabeleireir|cabelo|manicure|pedicure|barbearia|massagem|bioestetica|terapia|ortodontia|ortoped|oftalmolog|cardiolog|pediatra|ginecolog|fonoaudiolog|quiropraxia|acupuntura|podolog|optica|cosmetic|laboratorio|beleza|beauty|salon|hair|hairdress|coiffeur|facial|harmonizacao|botox|diagnostico|especialidade|loira|dra)\M)' THEN
    RETURN 'Saúde/Cuidados Estéticos';
  ELSIF n ~ '\m(energia|combustivel|gasolina|diesel|petroleo|lubrificante|glp|gnv|gas|solar|eolica|fotovoltaica|posto|etanol|querosene|biocombustivel)\M' THEN
    RETURN 'Energia/Combustíveis';
  ELSIF n ~ '\m(braseiro|churrascaria|churrasco|restaurante|lanchonete|lanchon|pizzaria|cafeteria|cafe|padaria|confeitaria|confeit|burger|hamburguer|hamburgueria|mercado|supermercado|acougue|peixaria|food|comida|refeicao|doceria|sorveteria|emporia|emporio|mercearia|bar|barzinh|alimento|pizza|pizzeria|ristorante|trattoria|osteria|resto|brasa|bife|mamma|cantina|degust|sushi|sushis|japa|temakeria|temaki|cervejaria|choperia|parmegiana|parmesa|margherita|boteco|pastel|pastelaria|acai|açaí|crepe|creperia|frutaria)' THEN
    RETURN 'Alimentação/Restaurantes';
  ELSIF n ~ '\m(loja|magazine|boutique|vestuario|roupa|calcados|sapato|departamento|varejo|shopping|mercadinh|empory|comercio|ecommerce|e-commerce|venda)' THEN
    RETURN 'Varejo/Comércio';
  ELSIF n ~ '\m(construcao|engenharia|reforma|eletrica|hidraulica|pedreiro|marcenaria|pintura|moveis|movel|serralheria|alvenaria|telhado|pavimentacao|climatizacao|manutencao|reparacao|conserto|maquina|ferramenta|instalacao|montagem)' THEN
    RETURN 'Construção/Serviços';
  ELSIF n ~ '\m(limpeza|asseio|conservacao|portaria|facilities|terceirizad|zeladoria|predial|servic)' THEN
    RETURN 'Serviços Gerais/Limpeza';
  ELSIF n ~ '\m(tecnologia|software|sistema|informatica|desenvolvimento|digital|dados|cloud|computador|marketingdigital|aplicativo|web|app|ti\M)' THEN
    RETURN 'Tecnologia/Software';
  ELSIF n ~ '\m(agencia|marketing|publicidade|propaganda|midia|media|publicitari|branding|comunicacao|socialmedia|influencer|fotograf|livr|editora|edicao|publicacao|impressao)' THEN
    RETURN 'Marketing/Publicidade';
  ELSIF n ~ '\m(escola|curso|ensino|educacao|faculdade|universidade|treinamento|idioma|professor|professora|colegio|creche|bercario|mentoria|aula)' THEN
    RETURN 'Educação';
  ELSIF n ~ '\m(imobiliaria|imovel|imoveis|corretor|loteamento|incorporadora)' THEN
    RETURN 'Imobiliário';
  ELSIF n ~ '\m(advocacia|advogado|juridico|juridica)' THEN
    RETURN 'Advocacia/Jurídico';
  ELSIF n ~ '\m(contabilidade|contador|financeiro|auditoria)' THEN
    RETURN 'Contabilidade/Financeiro';
  ELSIF n ~ '\m(transporte|logistica|frete|entrega|mudanca|correio)' OR n LIKE '%delivery%' THEN
    RETURN 'Transporte/Logística';
  ELSIF n ~ '\m(automovel|automotivo|autocenter|autopeca|oficina|mecanica|veiculo|lavagem|esteticaautomotiva)' THEN
    RETURN 'Automotivo';
  ELSIF n ~ '\m(pet\M|petshop|veterinario|veterinaria|tosa|banhoetosa)' THEN
    RETURN 'Pet Shop/Veterinária';
  ELSIF n ~ '\m(agro|fazenda|rural|agronegocio)' THEN
    RETURN 'Agronegócio';
  ELSIF n ~ '\m(industria|fabricacao|fabrica|manufatura)' THEN
    RETURN 'Indústria';
  ELSIF n ~ '\m(seguranca|vigilancia|monitoramento|blindagem|portariaarmada)' THEN
    RETURN 'Segurança';
  ELSIF n ~ '\m(hotel|hoteis|motel|moteis|hostel|hosteis|pousada|turismo|viagem|travel|resort|resorts|inn|flat)\M' THEN
    RETURN 'Hotelaria/Turismo';
  ELSIF n ~ '\m(evento|festa|buffet|ceremonial|decoracao)' THEN
    RETURN 'Eventos/Celebrações';
  ELSIF n ~ '\m(academia|fitness|crossfit|musculacao|pilates|funcional)' THEN
    RETURN 'Fitness/Academia';
  ELSIF n ~ '\m(consultoria|mao de obra|agenciamento|recursos humanos|rh\M)' THEN
    RETURN 'Serviços Gerais/Limpeza';
  END IF;
  RETURN NULL;
END;
$function$;
