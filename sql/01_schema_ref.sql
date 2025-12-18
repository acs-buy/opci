-- Schéma de référentiels pour la mission de présentation des comptes OPCI (NEP 2300)
-- Objectif : fournir les référentiels (plan comptable, contrôles, diligences, dimensions OPCI)
-- pour structurer les diligences de cohérence/vraisemblance et la documentation du dossier de travail.

-- Création du schéma ref si absent
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ref')
BEGIN
    EXEC('CREATE SCHEMA ref');
END;

/* Table: ref.plan_comptable
   Rôle NEP 2300 : référentiel des comptes pour appuyer les contrôles de cohérence/vraisemblance et la documentation du dossier de travail. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'ref' AND t.name = 'plan_comptable'
)
BEGIN
    CREATE TABLE ref.plan_comptable (
        account_id             INT              NOT NULL IDENTITY(1,1) CONSTRAINT PK_ref_plan_comptable PRIMARY KEY,
        account_number         NVARCHAR(20)     NOT NULL,
        account_label          NVARCHAR(255)    NOT NULL,
        account_class          NVARCHAR(10)     NULL,
        account_type           NVARCHAR(50)     NULL,
        parent_account_number  NVARCHAR(20)     NULL,
        country_code           NVARCHAR(5)      NOT NULL CONSTRAINT DF_ref_plan_comptable_country_code DEFAULT (N'FR'),
        source                 NVARCHAR(50)     NULL,
        created_at             DATETIME2        NOT NULL CONSTRAINT DF_ref_plan_comptable_created_at DEFAULT SYSUTCDATETIME(),
        created_by             NVARCHAR(100)    NOT NULL CONSTRAINT DF_ref_plan_comptable_created_by DEFAULT (N'system'),
        modified_at            DATETIME2        NULL,
        modified_by            NVARCHAR(100)    NULL,
        is_active              BIT              NOT NULL CONSTRAINT DF_ref_plan_comptable_is_active DEFAULT (1),
        CONSTRAINT UQ_ref_plan_comptable_account UNIQUE (account_number, country_code)
    );
END;

/* Table: ref.control_catalog
   Rôle NEP 2300 : référentiel des contrôles de cohérence/vraisemblance (catalogue), sans exécution automatique. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'ref' AND t.name = 'control_catalog'
)
BEGIN
    CREATE TABLE ref.control_catalog (
        control_code        NVARCHAR(50)   NOT NULL CONSTRAINT PK_ref_control_catalog PRIMARY KEY,
        control_label       NVARCHAR(200)  NOT NULL,
        control_description NVARCHAR(1000) NULL,
        control_category    NVARCHAR(100)  NULL,
        severity_hint       NVARCHAR(20)   NULL,
        requires_comment    BIT            NOT NULL CONSTRAINT DF_ref_control_catalog_requires_comment DEFAULT (1),
        created_at          DATETIME2      NOT NULL CONSTRAINT DF_ref_control_catalog_created_at DEFAULT SYSUTCDATETIME(),
        created_by          NVARCHAR(100)  NOT NULL CONSTRAINT DF_ref_control_catalog_created_by DEFAULT (N'system'),
        modified_at         DATETIME2      NULL,
        modified_by         NVARCHAR(100)  NULL,
        is_active           BIT            NOT NULL CONSTRAINT DF_ref_control_catalog_is_active DEFAULT (1)
    );
END;

-- Suppression de la contrainte unique redondante sur control_code si présente (PK déjà unique)
IF EXISTS (
    SELECT 1
    FROM sys.key_constraints kc
    WHERE kc.name = 'UQ_ref_control_catalog_code'
      AND kc.parent_object_id = OBJECT_ID('ref.control_catalog')
)
BEGIN
    ALTER TABLE ref.control_catalog DROP CONSTRAINT UQ_ref_control_catalog_code;
END;

/* Table: ref.diligence_catalog
   Rôle NEP 2300 : référentiel des diligences proposées pour le programme de travail de présentation (indicatif, validé par l'expert). */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'ref' AND t.name = 'diligence_catalog'
)
BEGIN
    CREATE TABLE ref.diligence_catalog (
        diligence_code        NVARCHAR(50)   NOT NULL CONSTRAINT PK_ref_diligence_catalog PRIMARY KEY,
        diligence_label       NVARCHAR(200)  NOT NULL,
        diligence_description NVARCHAR(1000) NULL,
        cycle                 NVARCHAR(100)  NULL,
        trigger_control_code  NVARCHAR(50)   NULL,
        default_status        NVARCHAR(30)   NOT NULL CONSTRAINT DF_ref_diligence_catalog_default_status DEFAULT (N'À planifier'),
        requires_validation   BIT            NOT NULL CONSTRAINT DF_ref_diligence_catalog_requires_validation DEFAULT (1),
        created_at            DATETIME2      NOT NULL CONSTRAINT DF_ref_diligence_catalog_created_at DEFAULT SYSUTCDATETIME(),
        created_by            NVARCHAR(100)  NOT NULL CONSTRAINT DF_ref_diligence_catalog_created_by DEFAULT (N'system'),
        modified_at           DATETIME2      NULL,
        modified_by           NVARCHAR(100)  NULL,
        is_active             BIT            NOT NULL CONSTRAINT DF_ref_diligence_catalog_is_active DEFAULT (1),
        CONSTRAINT FK_ref_diligence_catalog_control FOREIGN KEY (trigger_control_code) REFERENCES ref.control_catalog(control_code)
    );
END;

/* Table: ref.opci_dimensions
   Rôle NEP 2300 : référentiel minimal pour classifier des éléments OPCI et faciliter la documentation des diligences. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'ref' AND t.name = 'opci_dimensions'
)
BEGIN
    CREATE TABLE ref.opci_dimensions (
        dim_type      NVARCHAR(50)   NOT NULL,
        dim_code      NVARCHAR(50)   NOT NULL,
        dim_label     NVARCHAR(200)  NOT NULL,
        created_at    DATETIME2      NOT NULL CONSTRAINT DF_ref_opci_dimensions_created_at DEFAULT SYSUTCDATETIME(),
        created_by    NVARCHAR(100)  NOT NULL CONSTRAINT DF_ref_opci_dimensions_created_by DEFAULT (N'system'),
        modified_at   DATETIME2      NULL,
        modified_by   NVARCHAR(100)  NULL,
        is_active     BIT            NOT NULL CONSTRAINT DF_ref_opci_dimensions_is_active DEFAULT (1),
        CONSTRAINT PK_ref_opci_dimensions PRIMARY KEY (dim_type, dim_code)
    );
END;

-- Index sur plan_comptable.account_number
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_ref_plan_comptable_account_number' AND i.object_id = OBJECT_ID('ref.plan_comptable')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ref_plan_comptable_account_number
        ON ref.plan_comptable(account_number);
END;

-- Index sur diligence_catalog.trigger_control_code
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_ref_diligence_catalog_trigger' AND i.object_id = OBJECT_ID('ref.diligence_catalog')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ref_diligence_catalog_trigger
        ON ref.diligence_catalog(trigger_control_code);
END;

-- Données seed minimales : contrôles (cohérence/format/variations) avec codes MVP_
IF NOT EXISTS (SELECT 1 FROM ref.control_catalog WHERE control_code = N'MVP_CTRL_FORMAT_BALANCE')
BEGIN
    INSERT INTO ref.control_catalog (control_code, control_label, control_description, control_category, severity_hint, requires_comment, created_by)
    VALUES (N'MVP_CTRL_FORMAT_BALANCE', N'Format balance', N'Vérification du format et des totaux de la balance importée.', N'format', N'attention', 1, N'system');
END;

IF NOT EXISTS (SELECT 1 FROM ref.control_catalog WHERE control_code = N'MVP_CTRL_EQ_DC')
BEGIN
    INSERT INTO ref.control_catalog (control_code, control_label, control_description, control_category, severity_hint, requires_comment, created_by)
    VALUES (N'MVP_CTRL_EQ_DC', N'Équilibre débit/crédit', N'Contrôle mécanique d''équilibre global débit/crédit.', N'cohérence', N'significatif', 1, N'system');
END;

IF NOT EXISTS (SELECT 1 FROM ref.control_catalog WHERE control_code = N'MVP_CTRL_VAR_SIGNIF')
BEGIN
    INSERT INTO ref.control_catalog (control_code, control_label, control_description, control_category, severity_hint, requires_comment, created_by)
    VALUES (N'MVP_CTRL_VAR_SIGNIF', N'Variations significatives', N'Analyse des variations N/N-1 sur agrégats clés.', N'vraisemblance', N'attention', 1, N'system');
END;

-- Données seed minimales : diligences liées aux contrôles (codes MVP_/EXEMPLE_)
IF NOT EXISTS (SELECT 1 FROM ref.diligence_catalog WHERE diligence_code = N'MVP_DIL_BALANCE_FORMAT')
BEGIN
    INSERT INTO ref.diligence_catalog (diligence_code, diligence_label, diligence_description, cycle, trigger_control_code, default_status, requires_validation, created_by)
    VALUES (N'MVP_DIL_BALANCE_FORMAT', N'Revue du format de la balance', N'Vérification du format et de la complétude de la balance importée.', N'cycle général', N'MVP_CTRL_FORMAT_BALANCE', N'À planifier', 1, N'system');
END;

IF NOT EXISTS (SELECT 1 FROM ref.diligence_catalog WHERE diligence_code = N'MVP_DIL_EQ_DC')
BEGIN
    INSERT INTO ref.diligence_catalog (diligence_code, diligence_label, diligence_description, cycle, trigger_control_code, default_status, requires_validation, created_by)
    VALUES (N'MVP_DIL_EQ_DC', N'Revue équilibre débit/crédit', N'Analyser l''équilibre global et commenter les écarts éventuels.', N'cycle général', N'MVP_CTRL_EQ_DC', N'À planifier', 1, N'system');
END;

IF NOT EXISTS (SELECT 1 FROM ref.diligence_catalog WHERE diligence_code = N'EXEMPLE_DIL_VAR_SIGNIF')
BEGIN
    INSERT INTO ref.diligence_catalog (diligence_code, diligence_label, diligence_description, cycle, trigger_control_code, default_status, requires_validation, created_by)
    VALUES (N'EXEMPLE_DIL_VAR_SIGNIF', N'Analyse variations significatives', N'Identifier les variations N/N-1 à commenter dans le dossier.', N'produits/charges', N'MVP_CTRL_VAR_SIGNIF', N'À planifier', 1, N'system');
END;
