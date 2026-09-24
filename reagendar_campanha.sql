CREATE OR REPLACE FUNCTION next_business_slot_pl(from_ts timestamptz, start_h int DEFAULT 9, end_h int DEFAULT 19)
RETURNS timestamptz AS $$
DECLARE
  d timestamptz;
  h int;
BEGIN
  d := from_ts AT TIME ZONE 'America/Sao_Paulo';
  h := EXTRACT(HOUR FROM d);
  IF h < start_h OR h >= end_h THEN
    IF h >= end_h THEN d := d + interval '1 day'; END IF;
    d := date_trunc('day', d) + make_interval(hours => start_h);
  END IF;
  -- pula sabado(6)/domingo(0)
  WHILE EXTRACT(ISODOW FROM d) IN (6, 7) LOOP
    d := d + interval '1 day';
    d := date_trunc('day', d) + make_interval(hours => start_h);
  END LOOP;
  RETURN d AT TIME ZONE 'America/Sao_Paulo';
END;
$$ LANGUAGE plpgsql;

-- Reagenda os 50 da campanha respeitando janela 9-19h e espacamento de 20min.
DO $$
DECLARE
  r record;
  base timestamptz;
  step int := 1200; -- 20 min
  i int := 0;
BEGIN
  -- comeca no proximo slot valido apos agora (ou agora se dentro da janela)
  base := next_business_slot_pl(now(), 9, 19);
  FOR r IN
    SELECT dq.id, dq.scheduled_at
    FROM dispatch_queue dq
    JOIN campaign_recipients cr ON cr.dispatch_queue_ids && ARRAY[dq.id]
    JOIN campaigns c ON c.id = cr.campaign_id
    WHERE c.user_id = '137fd3ed-4591-4abb-99a3-a091a085f7d5' AND dq.status = 'pending'
    ORDER BY dq.scheduled_at ASC
  LOOP
    base := next_business_slot_pl(base, 9, 19);
    UPDATE dispatch_queue SET scheduled_at = base WHERE id = r.id;
    base := base + make_interval(secs => step);
    i := i + 1;
  END LOOP;
  RAISE NOTICE 'reagendados: %', i;
END $$;
