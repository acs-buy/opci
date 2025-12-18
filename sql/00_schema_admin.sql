-- Schéma d'administration pour la mission de présentation des comptes OPCI (NEP 2300)
-- Tables de référence : cabinets, missions, exercices, utilisateurs, rôles et affectations

-- Créer le schéma admin si absent
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'admin')
BEGIN
    EXEC('CREATE SCHEMA admin');
END;

/* Table: admin.cabinets
   Rôle NEP 2300 : identifier le cabinet responsable de la mission de présentation, pour tracer les diligences. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'cabinets'
)
BEGIN
    CREATE TABLE admin.cabinets (
        cabinet_id       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_admin_cabinets PRIMARY KEY DEFAULT NEWID(),
        code             NVARCHAR(50)     NOT NULL,
        name             NVARCHAR(200)    NOT NULL,
        country_code     NVARCHAR(5)      NULL,
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_admin_cabinets_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_admin_cabinets_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_admin_cabinets_is_active DEFAULT (1),
        CONSTRAINT UQ_admin_cabinets_code UNIQUE (code)
    );
END;

/* Table: admin.missions
   Rôle NEP 2300 : recenser chaque mission de présentation des comptes OPCI associée à un cabinet. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'missions'
)
BEGIN
    CREATE TABLE admin.missions (
        mission_id       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_admin_missions PRIMARY KEY DEFAULT NEWID(),
        cabinet_id       UNIQUEIDENTIFIER NOT NULL,
        mission_label    NVARCHAR(200)    NOT NULL,
        description      NVARCHAR(500)    NULL,
        start_date       DATE             NULL,
        end_date         DATE             NULL,
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_admin_missions_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_admin_missions_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_admin_missions_is_active DEFAULT (1),
        CONSTRAINT FK_admin_missions_cabinet FOREIGN KEY (cabinet_id) REFERENCES admin.cabinets(cabinet_id)
    );
END;

/* Table: admin.exercices
   Rôle NEP 2300 : suivre les exercices rattachés à une mission de présentation pour documenter la période contrôlée en cohérence/vraisemblance. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'exercices'
)
BEGIN
    CREATE TABLE admin.exercices (
        exercice_id      UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_admin_exercices PRIMARY KEY DEFAULT NEWID(),
        mission_id       UNIQUEIDENTIFIER NOT NULL,
        exercice_label   NVARCHAR(100)    NOT NULL,
        date_start       DATE             NULL,
        date_end         DATE             NULL,
        is_closed        BIT              NOT NULL CONSTRAINT DF_admin_exercices_is_closed DEFAULT (0),
        created_at       DATETIME2        NOT NULL CONSTRAINT DF_admin_exercices_created_at DEFAULT SYSUTCDATETIME(),
        created_by       NVARCHAR(100)    NOT NULL CONSTRAINT DF_admin_exercices_created_by DEFAULT (N'system'),
        modified_at      DATETIME2        NULL,
        modified_by      NVARCHAR(100)    NULL,
        is_active        BIT              NOT NULL CONSTRAINT DF_admin_exercices_is_active DEFAULT (1),
        CONSTRAINT FK_admin_exercices_mission FOREIGN KEY (mission_id) REFERENCES admin.missions(mission_id)
    );
END;

/* Table: admin.utilisateurs
   Rôle NEP 2300 : référencer les utilisateurs intervenant sur la mission de présentation et assurer la traçabilité des diligences. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'utilisateurs'
)
BEGIN
    CREATE TABLE admin.utilisateurs (
        user_id         UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_admin_utilisateurs PRIMARY KEY DEFAULT NEWID(),
        cabinet_id      UNIQUEIDENTIFIER NOT NULL,
        email           NVARCHAR(255)    NOT NULL,
        display_name    NVARCHAR(200)    NOT NULL,
        phone_number    NVARCHAR(50)     NULL,
        created_at      DATETIME2        NOT NULL CONSTRAINT DF_admin_utilisateurs_created_at DEFAULT SYSUTCDATETIME(),
        created_by      NVARCHAR(100)    NOT NULL CONSTRAINT DF_admin_utilisateurs_created_by DEFAULT (N'system'),
        modified_at     DATETIME2        NULL,
        modified_by     NVARCHAR(100)    NULL,
        is_active       BIT              NOT NULL CONSTRAINT DF_admin_utilisateurs_is_active DEFAULT (1),
        CONSTRAINT FK_admin_utilisateurs_cabinet FOREIGN KEY (cabinet_id) REFERENCES admin.cabinets(cabinet_id),
        CONSTRAINT UQ_admin_utilisateurs_cabinet_email UNIQUE (cabinet_id, email)
    );
END;

/* Table: admin.roles
   Rôle NEP 2300 : définir les rôles métiers (ex : mission manager, analyste) pour attribuer les diligences et validations. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'roles'
)
BEGIN
    CREATE TABLE admin.roles (
        role_id         INT             NOT NULL IDENTITY(1,1) CONSTRAINT PK_admin_roles PRIMARY KEY,
        code            NVARCHAR(50)    NOT NULL,
        label           NVARCHAR(100)   NOT NULL,
        description     NVARCHAR(255)   NULL,
        created_at      DATETIME2       NOT NULL CONSTRAINT DF_admin_roles_created_at DEFAULT SYSUTCDATETIME(),
        created_by      NVARCHAR(100)   NOT NULL CONSTRAINT DF_admin_roles_created_by DEFAULT (N'system'),
        modified_at     DATETIME2       NULL,
        modified_by     NVARCHAR(100)   NULL,
        is_active       BIT             NOT NULL CONSTRAINT DF_admin_roles_is_active DEFAULT (1),
        CONSTRAINT UQ_admin_roles_code UNIQUE (code)
    );
END;

/* Table: admin.utilisateurs_roles
   Rôle NEP 2300 : tracer l'affectation des rôles aux utilisateurs par mission/exercice pour sécuriser la responsabilité et la cohérence des diligences. */
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'admin' AND t.name = 'utilisateurs_roles'
)
BEGIN
    CREATE TABLE admin.utilisateurs_roles (
        utilisateur_role_id BIGINT          NOT NULL IDENTITY(1,1) CONSTRAINT PK_admin_utilisateurs_roles PRIMARY KEY,
        user_id             UNIQUEIDENTIFIER NOT NULL,
        role_id             INT             NOT NULL,
        mission_id          UNIQUEIDENTIFIER NULL,
        exercice_id         UNIQUEIDENTIFIER NULL,
        scope_comment       NVARCHAR(255)   NULL,
        created_at          DATETIME2       NOT NULL CONSTRAINT DF_admin_utilisateurs_roles_created_at DEFAULT SYSUTCDATETIME(),
        created_by          NVARCHAR(100)   NOT NULL CONSTRAINT DF_admin_utilisateurs_roles_created_by DEFAULT (N'system'),
        modified_at         DATETIME2       NULL,
        modified_by         NVARCHAR(100)   NULL,
        is_active           BIT             NOT NULL CONSTRAINT DF_admin_utilisateurs_roles_is_active DEFAULT (1),
        CONSTRAINT FK_admin_utilroles_user FOREIGN KEY (user_id) REFERENCES admin.utilisateurs(user_id),
        CONSTRAINT FK_admin_utilroles_role FOREIGN KEY (role_id) REFERENCES admin.roles(role_id),
        CONSTRAINT FK_admin_utilroles_mission FOREIGN KEY (mission_id) REFERENCES admin.missions(mission_id),
        CONSTRAINT FK_admin_utilroles_exercice FOREIGN KEY (exercice_id) REFERENCES admin.exercices(exercice_id),
        CONSTRAINT CK_admin_utilroles_scope CHECK (mission_id IS NOT NULL OR exercice_id IS NOT NULL)
    );
END;

-- Supprimer l'ancienne contrainte d'unicité si elle existe (pour réintroduire des indexes filtrés)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilroles_mission_exercice'
      AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilroles_mission_exercice
    ON admin.utilisateurs_roles(mission_id, exercice_id);
END;


-- Indexation de base sur les clés étrangères (création conditionnelle)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_missions_cabinet' AND i.object_id = OBJECT_ID('admin.missions')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_missions_cabinet ON admin.missions(cabinet_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_exercices_mission' AND i.object_id = OBJECT_ID('admin.exercices')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_exercices_mission ON admin.exercices(mission_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilisateurs_cabinet' AND i.object_id = OBJECT_ID('admin.utilisateurs')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilisateurs_cabinet ON admin.utilisateurs(cabinet_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilroles_user' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilroles_user ON admin.utilisateurs_roles(user_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilroles_role' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilroles_role ON admin.utilisateurs_roles(role_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilroles_mission' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilroles_mission ON admin.utilisateurs_roles(mission_id);
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'IX_admin_utilroles_exercice' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_utilroles_exercice ON admin.utilisateurs_roles(exercice_id);
END;

-- Unicité filtrée (mission sans exercice)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'UX_admin_utilroles_mission_scope' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_admin_utilroles_mission_scope
        ON admin.utilisateurs_roles(user_id, role_id, mission_id)
        WHERE exercice_id IS NULL;
END;

-- Unicité filtrée (exercice)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.name = 'UX_admin_utilroles_exercice_scope' AND i.object_id = OBJECT_ID('admin.utilisateurs_roles')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_admin_utilroles_exercice_scope
        ON admin.utilisateurs_roles(user_id, role_id, exercice_id)
        WHERE exercice_id IS NOT NULL;
END;
