-- Cria a tabela de workflow de vídeos e índices associados
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS tb_video_workflow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    video_id VARCHAR(255) NOT NULL,
    upload_path VARCHAR(500) NOT NULL,
    output_path VARCHAR(500),
    status VARCHAR(50) NOT NULL,
    error_message VARCHAR(255),
    uploaded_at TIMESTAMP,
    processed_at TIMESTAMP,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Índices importantes
CREATE INDEX IF NOT EXISTS idx_workflow_status
    ON tb_video_workflow(status);

CREATE INDEX IF NOT EXISTS idx_workflow_video_id
    ON tb_video_workflow(video_id);

CREATE INDEX IF NOT EXISTS idx_workflow_user_id
    ON tb_video_workflow(user_id);

