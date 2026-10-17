-- Perfil de muestreo de PRODUCCIÓN: vuelve a los periodos por defecto de PARAMETERS.
--
--   docker compose exec -T postgresql psql -U postgres-sbc-pms -d db_sbc_pms < postgresql/scripts/perfil_produccion.sql

UPDATE DEVICE_READING_SETTINGS drs
SET PERIOD = p.DEFAULT_PERIOD
FROM PARAMETERS p, DEVICES d
WHERE drs.PARAMETER = p.ID_PARAMETER
  AND drs.ID_DEVICE = d.ID_DEVICE
  AND d.ACTIVE = TRUE
  AND drs.PARAMETER IN ('cpu_freq', 'pressure', 'cpu_temp', 'ram', 'load_average', 'cpu_usage');

INSERT INTO DEVICE_UPDATES (ID_DEVICE, HASH_UPDATE, ID_TYPE)
SELECT ID_DEVICE, substr(md5(random()::text), 1, 12), 'update'
FROM DEVICES WHERE ACTIVE = TRUE;

SELECT ID_DEVICE, PARAMETER, PERIOD FROM DEVICE_READING_SETTINGS
WHERE PARAMETER IN ('cpu_freq', 'pressure', 'cpu_temp', 'ram', 'load_average', 'cpu_usage')
ORDER BY ID_DEVICE, PARAMETER;
