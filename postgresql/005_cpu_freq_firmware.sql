-- =====================================================================
-- 005_cpu_freq_firmware.sql  (idempotente: seguro de re-ejecutar)
-- La frecuencia pasa a leerse del FIRMWARE en Raspberry Pi (vcgencmd), porque
-- cpufreq/sysfs muestra la frecuencia solicitada y no el throttling real
-- (medido en NODE001: sysfs 1800 MHz mientras el clock real bajaba a 600–1600 MHz).
-- Debe ejecutarse DESPUÉS de 003_fl_telemetry.sql.
-- =====================================================================

ALTER TABLE CPU_FREQUENCY ADD COLUMN IF NOT EXISTS FREQ_SOURCE     VARCHAR(20); -- 'firmware' | 'sysfs'
ALTER TABLE CPU_FREQUENCY ADD COLUMN IF NOT EXISTS THROTTLED_FLAGS INT;         -- vcgencmd get_throttled
ALTER TABLE CPU_FREQUENCY ADD COLUMN IF NOT EXISTS THROTTLED_NOW   BOOLEAN;     -- bits 1–3 activos

-- Las filas previas se midieron con sysfs.
UPDATE CPU_FREQUENCY SET FREQ_SOURCE = 'sysfs' WHERE FREQ_SOURCE IS NULL;
