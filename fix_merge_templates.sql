-- Corrige mensagens com templates {{...}} nos leads da campanha "Esteticas"
-- Mergeia {{nome}} e {{empresa}} pelos valores do lead
DO $$
DECLARE
  r record;
  msg text;
  nome_val text;
  emp_val text;
BEGIN
  FOR r IN
    SELECT dq.id AS dq_id, dq.mensagem AS tpl, cr.campaign_id, cr.source, cr.source_id,
           l.nome_contato, l.nome_empresa
    FROM dispatch_queue dq
    JOIN campaign_recipients cr ON cr.dispatch_queue_ids && ARRAY[dq.id]
    JOIN campaigns c ON c.id = cr.campaign_id
    LEFT JOIN leads l ON l.id = cr.source_id AND cr.source = 'leads'
    WHERE c.user_id = '137fd3ed-4591-4abb-99a3-a091a085f7d5'
      AND dq.status = 'pending'
      AND dq.mensagem LIKE '%{{%'
  LOOP
    msg := r.tpl;
    nome_val := r.nome_contato;
    -- para leads que não têm nome_contato, tenta usar nome_empresa
    IF nome_val IS NULL THEN
      nome_val := r.nome_empresa;
    END IF;
    emp_val := r.nome_empresa;
    -- faz replaces
    IF nome_val IS NOT NULL THEN
      msg := replace(msg, '{{nome}}', nome_val);
    END IF;
    IF emp_val IS NOT NULL THEN
      msg := replace(msg, '{{empresa}}', emp_val);
    END IF;
    UPDATE dispatch_queue SET mensagem = msg WHERE id = r.dq_id;
  END LOOP;
END $$;
-- verifica resultado
SELECT count(*) AS corrigidos FROM dispatch_queue dq
JOIN campaign_recipients cr ON cr.dispatch_queue_ids && ARRAY[dq.id]
JOIN campaigns c ON c.id = cr.campaign_id
WHERE c.user_id = '137fd3ed-4591-4abb-99a3-a091a085f7d5'
  AND dq.status = 'pending'
  AND dq.mensagem LIKE '%{{%';