CREATE OR REPLACE FUNCTION validar_telefone_empresa() RETURNS trigger AS $$
DECLARE
  ddd_tel text; uf_telefone text; uf_empresa text; cnpj_d text;
BEGIN
  IF NEW.telefone IS NULL OR NEW.telefone !~ '^55' THEN RETURN NEW; END IF;
  ddd_tel := substring(regexp_replace(NEW.telefone,'[^0-9]','','g') from 3 for 2);
  IF ddd_tel IS NULL OR length(ddd_tel) <> 2 THEN RETURN NEW; END IF;
  uf_telefone := CASE ddd_tel
    WHEN '11' THEN 'SP' WHEN '12' THEN 'SP' WHEN '13' THEN 'SP' WHEN '14' THEN 'SP' WHEN '15' THEN 'SP' WHEN '16' THEN 'SP' WHEN '17' THEN 'SP' WHEN '18' THEN 'SP' WHEN '19' THEN 'SP'
    WHEN '21' THEN 'RJ' WHEN '22' THEN 'RJ' WHEN '24' THEN 'RJ'
    WHEN '27' THEN 'ES' WHEN '28' THEN 'ES'
    WHEN '31' THEN 'MG' WHEN '32' THEN 'MG' WHEN '33' THEN 'MG' WHEN '34' THEN 'MG' WHEN '35' THEN 'MG' WHEN '36' THEN 'MG' WHEN '37' THEN 'MG' WHEN '38' THEN 'MG'
    WHEN '41' THEN 'PR' WHEN '42' THEN 'PR' WHEN '43' THEN 'PR' WHEN '44' THEN 'PR' WHEN '45' THEN 'PR' WHEN '46' THEN 'PR'
    WHEN '47' THEN 'SC' WHEN '48' THEN 'SC' WHEN '49' THEN 'SC'
    WHEN '51' THEN 'RS' WHEN '53' THEN 'RS' WHEN '54' THEN 'RS' WHEN '55' THEN 'RS'
    WHEN '61' THEN 'DF' WHEN '62' THEN 'GO' WHEN '64' THEN 'GO'
    WHEN '63' THEN 'TO' WHEN '65' THEN 'MT' WHEN '66' THEN 'MT' WHEN '67' THEN 'MS' WHEN '68' THEN 'AC' WHEN '69' THEN 'RO'
    WHEN '71' THEN 'BA' WHEN '73' THEN 'BA' WHEN '74' THEN 'BA' WHEN '75' THEN 'BA' WHEN '77' THEN 'BA'
    WHEN '79' THEN 'SE' WHEN '81' THEN 'PE' WHEN '87' THEN 'PE' WHEN '82' THEN 'AL' WHEN '83' THEN 'PB' WHEN '84' THEN 'RN' WHEN '85' THEN 'CE' WHEN '88' THEN 'CE'
    WHEN '86' THEN 'PI' WHEN '89' THEN 'PI' WHEN '91' THEN 'PA' WHEN '93' THEN 'PA' WHEN '94' THEN 'PA' WHEN '92' THEN 'AM' WHEN '97' THEN 'AM' WHEN '95' THEN 'RR'
    WHEN '96' THEN 'AP' WHEN '98' THEN 'MA' WHEN '99' THEN 'MA'
    ELSE NULL END;
  IF uf_telefone IS NULL THEN RETURN NEW; END IF;
  cnpj_d := regexp_replace(NEW.cnpj,'[^0-9]','','g');
  uf_empresa := CASE substring(cnpj_d from 9 for 2)
    WHEN '11' THEN 'RO' WHEN '12' THEN 'AC' WHEN '13' THEN 'AM' WHEN '14' THEN 'RR' WHEN '15' THEN 'PA' WHEN '16' THEN 'AP' WHEN '17' THEN 'TO'
    WHEN '21' THEN 'MA' WHEN '22' THEN 'PI' WHEN '23' THEN 'CE' WHEN '24' THEN 'RN' WHEN '25' THEN 'PB' WHEN '26' THEN 'PE' WHEN '27' THEN 'AL' WHEN '28' THEN 'SE'
    WHEN '29' THEN 'BA' WHEN '31' THEN 'MG' WHEN '32' THEN 'ES' WHEN '33' THEN 'RJ' WHEN '35' THEN 'SP' WHEN '41' THEN 'PR' WHEN '42' THEN 'SC' WHEN '43' THEN 'RS'
    WHEN '50' THEN 'MS' WHEN '51' THEN 'MT' WHEN '52' THEN 'GO' WHEN '53' THEN 'DF'
    ELSE NULL END;
  IF uf_empresa IS NULL AND NEW.endereco IS NOT NULL THEN
    IF NEW.endereco ~* ',[ ]*([A-Z]{2})[ ,]' THEN uf_empresa := (regexp_match(NEW.endereco, ',[ ]*([A-Z]{2})[ ,]'))[1];
    ELSIF NEW.endereco ~* '\b([A-Z]{2})[ ]*[0-9]{5,8}$' THEN uf_empresa := (regexp_match(NEW.endereco, '\b([A-Z]{2})[ ]*[0-9]{5,8}$'))[1];
    END IF;
  END IF;
  IF uf_empresa IS NULL THEN RETURN NEW; END IF;
  IF uf_telefone <> uf_empresa THEN NEW.telefone := NULL; END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_telefone ON empresas_enriquecidas;
CREATE TRIGGER trg_validar_telefone BEFORE INSERT OR UPDATE OF telefone ON empresas_enriquecidas
  FOR EACH ROW EXECUTE FUNCTION validar_telefone_empresa();
