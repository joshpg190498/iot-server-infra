-- =====================================================================
-- 003_fl_telemetry.sql  
-- Métricas de hardware para la agregación consciente de la salud (FL).
--
--   cpu_freq : frecuencia actual / máxima  -> detecta throttling.
--   pressure : PSI del kernel (CPU y memoria) -> detecta contención.
--
-- HAS_THRESHOLD = FALSE: no generan alertas ni agregados horarios
-- (data-processing y threshold-validator los ignoran). Se consultan crudos,
-- dentro de la ventana de entrenamiento de cada ronda.
-- Debe ejecutarse DESPUÉS de 001_init.sql.
-- =====================================================================

CREATE TABLE IF NOT EXISTS CPU_FREQUENCY (
    ID SERIAL PRIMARY KEY,
    ID_DEVICE VARCHAR(255) REFERENCES DEVICES(ID_DEVICE),
    CUR_FREQ_MHZ DECIMAL(8, 2),
    MAX_FREQ_MHZ DECIMAL(8, 2),
    FREQ_RATIO DECIMAL(6, 4),                  -- 1.0 = frecuencia máxima
    COLLECTED_AT_UTC TIMESTAMP,
    INSERTED_AT_UTC TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ID_DEVICE, COLLECTED_AT_UTC)
);

CREATE TABLE IF NOT EXISTS PRESSURE_STALL (
    ID SERIAL PRIMARY KEY,
    ID_DEVICE VARCHAR(255) REFERENCES DEVICES(ID_DEVICE),
    CPU_SOME_AVG10 DECIMAL(6, 2),              -- % del tiempo con tareas esperando CPU (10 s)
    CPU_SOME_AVG60 DECIMAL(6, 2),
    CPU_SOME_TOTAL BIGINT,                     -- µs acumulados: presión exacta = Δtotal / Δt
    MEM_SOME_AVG10 DECIMAL(6, 2),
    MEM_FULL_AVG10 DECIMAL(6, 2),
    MEM_SOME_TOTAL BIGINT,
    MEM_FULL_TOTAL BIGINT,
    COLLECTED_AT_UTC TIMESTAMP,
    INSERTED_AT_UTC TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ID_DEVICE, COLLECTED_AT_UTC)
);

-- Índices para la consulta por ventana (dispositivo + rango de tiempo)
CREATE INDEX IF NOT EXISTS idx_cpu_frequency_window  ON CPU_FREQUENCY  (ID_DEVICE, COLLECTED_AT_UTC);
CREATE INDEX IF NOT EXISTS idx_pressure_stall_window ON PRESSURE_STALL (ID_DEVICE, COLLECTED_AT_UTC);
CREATE INDEX IF NOT EXISTS idx_cpu_temperature_window ON CPU_TEMPERATURE (ID_DEVICE, COLLECTED_AT_UTC);
CREATE INDEX IF NOT EXISTS idx_ram_usage_window      ON RAM_USAGE      (ID_DEVICE, COLLECTED_AT_UTC);
CREATE INDEX IF NOT EXISTS idx_load_average_window   ON LOAD_AVERAGE   (ID_DEVICE, COLLECTED_AT_UTC);

INSERT INTO PARAMETERS (ID_PARAMETER, DEFAULT_PERIOD, TABLE_POINTER, DESCRIPTION, HAS_THRESHOLD, DEFAULT_THRESHOLD_VALUE) VALUES
('cpu_freq', 5, 'CPU_FREQUENCY',  'Frecuencia de la CPU (throttling)',           FALSE, NULL),
('pressure', 5, 'PRESSURE_STALL', 'Presión de CPU y memoria (PSI del kernel)',    FALSE, NULL)
ON CONFLICT (ID_PARAMETER) DO NOTHING;

-- Los dispositivos ya registrados reciben los parámetros nuevos con su periodo por defecto.
INSERT INTO DEVICE_READING_SETTINGS (ID_DEVICE, PARAMETER, PERIOD, ACTIVE)
SELECT d.ID_DEVICE, p.ID_PARAMETER, p.DEFAULT_PERIOD, TRUE
FROM DEVICES d
CROSS JOIN PARAMETERS p
WHERE p.ID_PARAMETER IN ('cpu_freq', 'pressure')
ON CONFLICT (ID_DEVICE, PARAMETER) DO NOTHING;
