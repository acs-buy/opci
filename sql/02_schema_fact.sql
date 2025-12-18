-- Schéma des données (facts) pour la mission de présentation des comptes OPCI (NEP 2300)
-- Objectif : stocker imports (balance, GL, FEC), résultats de contrôles, commentaires du jugement professionnel
-- et programme de travail, sans logique d’audit ni conclusion automatique.

-- Création du schéma fact si absent
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fact')
BEGIN
    EXEC('CREATE SCHEMA fact');
END;

/* Table: fact.import_batches
   Rôle NEP 2300 : tracer techniquement les imports (balance/GL/FEC) pour le dossier de travail, sans logique d’audit. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'import_batches'
)
BEGIN
    CREATE TABLE fact.import_batches (
        import_batch_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_fact_import_batches PRIMARY KEY DEFAULT NEWID(),
        cabinet_id      UNIQUEIDENTIFIER NULL,
        mission_id      UNIQUEIDENTIFIER NULL,
        exercice_id     UNIQUEIDENTIFIER NOT NULL,
        source_type     NVARCHAR(30)     NOT NULL,
        source_filename NVARCHAR(260)    NULL,
        source_hash     NVARCHAR(64)     NULL,
        imported_at     DATETIME2        NOT NULL CONSTRAINT DF_fact_import_batches_imported_at DEFAULT SYSUTCDATETIME(),
        imported_by     NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_import_batches_imported_by DEFAULT (N'system'),
        status          NVARCHAR(30)     NOT NULL CONSTRAINT DF_fact_import_batches_status DEFAULT (N'Importé'),
        row_count       INT              NULL,
        notes           NVARCHAR(1000)   NULL,
        created_at      DATETIME2        NOT NULL CONSTRAINT DF_fact_import_batches_created_at DEFAULT SYSUTCDATETIME(),
        created_by      NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_import_batches_created_by DEFAULT (N'system'),
        modified_at     DATETIME2        NULL,
        modified_by     NVARCHAR(100)    NULL,
        is_active       BIT              NOT NULL CONSTRAINT DF_fact_import_batches_is_active DEFAULT (1),
        CONSTRAINT FK_fact_import_batches_cabinet  FOREIGN KEY (cabinet_id)  REFERENCES admin.cabinets(cabinet_id),
        CONSTRAINT FK_fact_import_batches_mission  FOREIGN KEY (mission_id)  REFERENCES admin.missions(mission_id),
        CONSTRAINT FK_fact_import_batches_exercice FOREIGN KEY (exercice_id) REFERENCES admin.exercices(exercice_id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_import_batches_exercice' AND i.object_id = OBJECT_ID('fact.import_batches')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_import_batches_exercice ON fact.import_batches(exercice_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_import_batches_source_type' AND i.object_id = OBJECT_ID('fact.import_batches')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_import_batches_source_type ON fact.import_batches(source_type);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_import_batches_imported_at' AND i.object_id = OBJECT_ID('fact.import_batches')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_import_batches_imported_at ON fact.import_batches(imported_at);
END;

/* Table: fact.balance
   Rôle NEP 2300 : stocker les lignes de balance importée pour les contrôles de cohérence/vraisemblance. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'balance'
)
BEGIN
    CREATE TABLE fact.balance (
        balance_id       BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_balance PRIMARY KEY,
        import_batch_id  UNIQUEIDENTIFIER NOT NULL,
        exercice_id      UNIQUEIDENTIFIER NOT NULL,
        account_number   NVARCHAR(20)     NOT NULL,
        account_label    NVARCHAR(255)    NULL,
        debit            DECIMAL(19,4)    NOT NULL CONSTRAINT DF_fact_balance_debit DEFAULT (0),
        credit           DECIMAL(19,4)    NOT NULL CONSTRAINT DF_fact_balance_credit DEFAULT (0),
        balance          DECIMAL(19,4)    NULL,
        currency_code    NVARCHAR(3)      NOT NULL CONSTRAINT DF_fact_balance_currency DEFAULT (N'EUR'),
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_fact_balance_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_balance_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_fact_balance_is_active DEFAULT (1),
        CONSTRAINT FK_fact_balance_batch    FOREIGN KEY (import_batch_id) REFERENCES fact.import_batches(import_batch_id),
        CONSTRAINT FK_fact_balance_exercice FOREIGN KEY (exercice_id)     REFERENCES admin.exercices(exercice_id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_balance_exercice_account' AND i.object_id = OBJECT_ID('fact.balance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_balance_exercice_account ON fact.balance(exercice_id, account_number);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_balance_import_batch' AND i.object_id = OBJECT_ID('fact.balance')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_balance_import_batch ON fact.balance(import_batch_id);
END;

/* Table: fact.grand_livre
   Rôle NEP 2300 : stocker les écritures du grand livre pour analyses de cohérence/vraisemblance. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'grand_livre'
)
BEGIN
    CREATE TABLE fact.grand_livre (
        gl_id            BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_grand_livre PRIMARY KEY,
        import_batch_id  UNIQUEIDENTIFIER NOT NULL,
        exercice_id      UNIQUEIDENTIFIER NOT NULL,
        posting_date     DATE             NULL,
        journal_code     NVARCHAR(20)     NULL,
        piece_number     NVARCHAR(50)     NULL,
        account_number   NVARCHAR(20)     NOT NULL,
        account_label    NVARCHAR(255)    NULL,
        description      NVARCHAR(500)    NULL,
        debit            DECIMAL(19,4)    NOT NULL CONSTRAINT DF_fact_grand_livre_debit DEFAULT (0),
        credit           DECIMAL(19,4)    NOT NULL CONSTRAINT DF_fact_grand_livre_credit DEFAULT (0),
        third_party      NVARCHAR(100)    NULL,
        currency_code    NVARCHAR(3)      NOT NULL CONSTRAINT DF_fact_grand_livre_currency DEFAULT (N'EUR'),
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_fact_grand_livre_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_grand_livre_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_fact_grand_livre_is_active DEFAULT (1),
        CONSTRAINT FK_fact_gl_batch    FOREIGN KEY (import_batch_id) REFERENCES fact.import_batches(import_batch_id),
        CONSTRAINT FK_fact_gl_exercice FOREIGN KEY (exercice_id)     REFERENCES admin.exercices(exercice_id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_gl_exercice_posting' AND i.object_id = OBJECT_ID('fact.grand_livre')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_gl_exercice_posting ON fact.grand_livre(exercice_id, posting_date);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_gl_exercice_account' AND i.object_id = OBJECT_ID('fact.grand_livre')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_gl_exercice_account ON fact.grand_livre(exercice_id, account_number);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_gl_import_batch' AND i.object_id = OBJECT_ID('fact.grand_livre')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_gl_import_batch ON fact.grand_livre(import_batch_id);
END;

/* Table: fact.fec_ecritures
   Rôle NEP 2300 : stocker les écritures FEC pour analyses de cohérence/vraisemblance. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'fec_ecritures'
)
BEGIN
    CREATE TABLE fact.fec_ecritures (
        fec_id          BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_fec_ecritures PRIMARY KEY,
        import_batch_id UNIQUEIDENTIFIER NOT NULL,
        exercice_id     UNIQUEIDENTIFIER NOT NULL,
        ecriture_date   DATE             NULL,
        journal_code    NVARCHAR(20)     NULL,
        ecriture_num    NVARCHAR(50)     NULL,
        compte_num      NVARCHAR(20)     NOT NULL,
        compte_lib      NVARCHAR(255)    NULL,
        libelle         NVARCHAR(500)    NULL,
        debit           DECIMAL(19,4)    NOT NULL,
        credit          DECIMAL(19,4)    NOT NULL,
        piece_ref       NVARCHAR(50)     NULL,
        ligne_num       INT              NULL,
        created_at      DATETIME2        NOT NULL CONSTRAINT DF_fact_fec_created_at DEFAULT SYSUTCDATETIME(),
        created_by      NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_fec_created_by DEFAULT (N'system'),
        modified_at     DATETIME2        NULL,
        modified_by     NVARCHAR(100)    NULL,
        is_active       BIT              NOT NULL CONSTRAINT DF_fact_fec_is_active DEFAULT (1),
        CONSTRAINT FK_fact_fec_batch    FOREIGN KEY (import_batch_id) REFERENCES fact.import_batches(import_batch_id),
        CONSTRAINT FK_fact_fec_exercice FOREIGN KEY (exercice_id)     REFERENCES admin.exercices(exercice_id)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_fec_exercice_date' AND i.object_id = OBJECT_ID('fact.fec_ecritures')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_fec_exercice_date ON fact.fec_ecritures(exercice_id, ecriture_date);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_fec_exercice_compte' AND i.object_id = OBJECT_ID('fact.fec_ecritures')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_fec_exercice_compte ON fact.fec_ecritures(exercice_id, compte_num);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_fec_import_batch' AND i.object_id = OBJECT_ID('fact.fec_ecritures')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_fec_import_batch ON fact.fec_ecritures(import_batch_id);
END;

/* Table: fact.controles
   Rôle NEP 2300 : conserver les résultats des contrôles de cohérence/vraisemblance (sans conclusion automatique). */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'controles'
)
BEGIN
    CREATE TABLE fact.controles (
        controle_id      BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_controles PRIMARY KEY,
        exercice_id      UNIQUEIDENTIFIER NOT NULL,
        control_code     NVARCHAR(50)     NOT NULL,
        executed_at      DATETIME2        NOT NULL CONSTRAINT DF_fact_controles_executed_at DEFAULT SYSUTCDATETIME(),
        execution_id     UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_fact_controles_execution_id DEFAULT NEWID(),
        status           NVARCHAR(30)     NOT NULL CONSTRAINT DF_fact_controles_status DEFAULT (N'À analyser'),
        result_summary   NVARCHAR(1000)   NULL,
        metric_value     DECIMAL(19,4)    NULL,
        threshold_hint   DECIMAL(19,4)    NULL,
        requires_comment BIT              NOT NULL CONSTRAINT DF_fact_controles_requires_comment DEFAULT (1),
        is_overridden    BIT              NOT NULL CONSTRAINT DF_fact_controles_is_overridden DEFAULT (0),
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_fact_controles_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_controles_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_fact_controles_is_active DEFAULT (1),
        CONSTRAINT FK_fact_controles_exercice FOREIGN KEY (exercice_id)  REFERENCES admin.exercices(exercice_id),
        CONSTRAINT FK_fact_controles_code     FOREIGN KEY (control_code) REFERENCES ref.control_catalog(control_code)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_controles_exercice_code' AND i.object_id = OBJECT_ID('fact.controles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_controles_exercice_code ON fact.controles(exercice_id, control_code);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_controles_execution_id' AND i.object_id = OBJECT_ID('fact.controles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_controles_execution_id ON fact.controles(execution_id);
END;

/* Table: fact.diligences
   Rôle NEP 2300 : programme de travail (diligences proposées puis suivies) sans conclusion automatique. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'diligences'
)
BEGIN
    CREATE TABLE fact.diligences (
        diligence_id      BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_diligences PRIMARY KEY,
        exercice_id       UNIQUEIDENTIFIER NOT NULL,
        diligence_code    NVARCHAR(50)     NULL,
        label             NVARCHAR(200)    NOT NULL,
        description       NVARCHAR(1000)   NULL,
        status            NVARCHAR(30)     NOT NULL CONSTRAINT DF_fact_diligences_status DEFAULT (N'À planifier'),
        assigned_to       NVARCHAR(100)    NULL,
        due_date          DATE             NULL,
        completed_at      DATETIME2        NULL,
        requires_validation BIT            NOT NULL CONSTRAINT DF_fact_diligences_requires_validation DEFAULT (1),
        validated_by      NVARCHAR(100)    NULL,
        validated_at      DATETIME2        NULL,
        created_at        DATETIME2        NOT NULL CONSTRAINT DF_fact_diligences_created_at DEFAULT SYSUTCDATETIME(),
        created_by        NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_diligences_created_by DEFAULT (N'system'),
        modified_at       DATETIME2        NULL,
        modified_by       NVARCHAR(100)    NULL,
        is_active         BIT              NOT NULL CONSTRAINT DF_fact_diligences_is_active DEFAULT (1),
        CONSTRAINT FK_fact_diligences_exercice FOREIGN KEY (exercice_id)    REFERENCES admin.exercices(exercice_id),
        CONSTRAINT FK_fact_diligences_code     FOREIGN KEY (diligence_code) REFERENCES ref.diligence_catalog(diligence_code)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_diligences_exercice_status' AND i.object_id = OBJECT_ID('fact.diligences')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_diligences_exercice_status ON fact.diligences(exercice_id, status);
END;
/* Table: fact.commentaires_expert
   Rôle NEP 2300 : documenter le jugement professionnel (commentaires) en lien avec contrôles/diligences, sans conclusion automatique. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'fact' AND t.name = 'commentaires_expert'
)
BEGIN
    CREATE TABLE fact.commentaires_expert (
        commentaire_id   BIGINT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_fact_commentaires_expert PRIMARY KEY,
        exercice_id      UNIQUEIDENTIFIER NOT NULL,
        controle_id      BIGINT           NULL,
        diligence_id     BIGINT           NULL,
        comment_text     NVARCHAR(MAX)    NOT NULL,
        conclusion_label NVARCHAR(50)     NULL,
        validated_by     NVARCHAR(100)    NULL,
        validated_at     DATETIME2        NULL,
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_fact_commentaires_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_fact_commentaires_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_fact_commentaires_is_active DEFAULT (1),
        CONSTRAINT FK_fact_commentaires_exercice FOREIGN KEY (exercice_id)  REFERENCES admin.exercices(exercice_id),
        CONSTRAINT FK_fact_commentaires_controle FOREIGN KEY (controle_id)  REFERENCES fact.controles(controle_id),
        CONSTRAINT FK_fact_commentaires_diligence FOREIGN KEY (diligence_id) REFERENCES fact.diligences(diligence_id),
        CONSTRAINT CK_fact_commentaires_link CHECK (controle_id IS NOT NULL OR diligence_id IS NOT NULL)
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_commentaires_exercice_controle' AND i.object_id = OBJECT_ID('fact.commentaires_expert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_commentaires_exercice_controle ON fact.commentaires_expert(exercice_id, controle_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_commentaires_exercice_diligence' AND i.object_id = OBJECT_ID('fact.commentaires_expert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_commentaires_exercice_diligence ON fact.commentaires_expert(exercice_id, diligence_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_fact_diligences_exercice_code' AND i.object_id = OBJECT_ID('fact.diligences')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_diligences_exercice_code ON fact.diligences(exercice_id, diligence_code);
END;
