-- =====================================================================
-- 004_fl_rounds.sql  (idempotente: seguro de re-ejecutar)
-- Registro por ronda y por nodo de la agregación consciente de la salud.
-- Debe ejecutarse DESPUÉS de 002_fl_schema.sql.
-- =====================================================================

-- Una misma ronda N se repite en cada ejecución (run) del entrenamiento:
-- la unicidad pasa a ser (modelo, run, ronda).
ALTER TABLE ROUND_FL ADD COLUMN IF NOT EXISTS RUN_ID  VARCHAR(100);
ALTER TABLE ROUND_FL ADD COLUMN IF NOT EXISTS VARIANT VARCHAR(30);
ALTER TABLE ROUND_FL ADD COLUMN IF NOT EXISTS LAMBDA  FLOAT;
ALTER TABLE ROUND_FL DROP CONSTRAINT IF EXISTS round_fl_id_model_round_number_key;
CREATE UNIQUE INDEX IF NOT EXISTS uq_round_fl_run ON ROUND_FL (ID_MODEL, RUN_ID, ROUND_NUMBER);

-- Por nodo: identidad, trabajo, telemetría cruda de la ventana y señales normalizadas.
-- ID_DEVICE solo se llena si el nodo existe en DEVICES (FK); DEVICE_LABEL siempre.
-- NODE_ID es un identificador opaco (Flower usa uint64, hasta 20 dígitos): se guarda
-- como texto, igual que ID_DEVICE. No cabe en BIGINT y, como número, JavaScript lo
-- redondearía en la web (solo representa enteros exactos hasta ~9e15).
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS NODE_ID           VARCHAR(50);
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS DEVICE_LABEL      VARCHAR(255);
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS STEPS_DONE        INT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS STEPS_PLANNED     INT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS CPU_PSI           FLOAT;   -- % tiempo esperando CPU
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS MEM_PSI           FLOAT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS FREQ_RATIO        FLOAT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS TEMP_MAX          FLOAT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS LOAD_PER_CORE     FLOAT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS RAM_PCT           FLOAT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS TELEMETRY_SAMPLES INT;
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS SIG_WORK          FLOAT;   -- e_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS SIG_CPU           FLOAT;   -- c_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS SIG_FREQ          FLOAT;   -- f_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS SIG_MEM           FLOAT;   -- m_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS SIG_TEMP          FLOAT;   -- θ_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS HW_STRESS         FLOAT;   -- H_k
ALTER TABLE UPDATES_FL ADD COLUMN IF NOT EXISTS STRESS            FLOAT;   -- s_k
-- HEALTH_WEIGHT (h_k) y AGGREGATION_WEIGHT (ω_k / Σω) ya existen en 002.
CREATE UNIQUE INDEX IF NOT EXISTS uq_updates_fl_node ON UPDATES_FL (ID_ROUND_FL, NODE_ID);
