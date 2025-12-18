-- Contrôle mécanique NEP 2300 : concordance balance / grand livre pour un exercice (aucune conclusion automatique)
-- Entrées :
--   @exercice_id  UNIQUEIDENTIFIER (obligatoire)
--   @execution_id UNIQUEIDENTIFIER (optionnel, généré si NULL)
--   @created_by   NVARCHAR(100) = 'system' par défaut
-- Sortie : insertion d'une ligne factuelle dans fact.controles et SELECT récapitulatif.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fact')
BEGIN
    EXEC('CREATE SCHEMA fact');
END;

-- S'assurer que le code de contrôle existe dans ref.control_catalog (idempotent)
IF OBJECT_ID('ref.control_catalog', 'U') IS NULL
BEGIN
    RAISERROR(N'Table ref.control_catalog absente. Exécuter au préalable sql/01_schema_ref.sql.', 16, 1);
    RETURN;
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ref.control_catalog WHERE control_code = N'MVP_CTRL_BALANCE_VS_GL')
    BEGIN
        INSERT INTO ref.control_catalog (
            control_code, control_label, control_description, control_category,
            severity_hint, requires_comment, created_at, created_by, modified_at, modified_by, is_active
        )
        VALUES (
            N'MVP_CTRL_BALANCE_VS_GL',
            N'Concordance balance / grand livre',
            N'Contrôle mécanique de cohérence des totaux débit/crédit entre balance et grand livre pour un exercice.',
            N'cohérence',
            N'attention',
            1,
            SYSUTCDATETIME(),
            N'system',
            NULL,
            NULL,
            1
        );
    END;
END;

CREATE OR ALTER PROCEDURE fact.usp_ctrl_balance_vs_gl
    @exercice_id  UNIQUEIDENTIFIER,
    @execution_id UNIQUEIDENTIFIER = NULL,
    @created_by   NVARCHAR(100) = N'system'
AS
BEGIN
    SET NOCOUNT ON;

    -- Garde-fous structurels
    IF OBJECT_ID('fact.controles', 'U') IS NULL
    BEGIN
        RAISERROR(N'Table fact.controles absente. Exécuter au préalable sql/02_schema_fact.sql.', 16, 1);
        RETURN;
    END;
    IF OBJECT_ID('fact.balance', 'U') IS NULL
    BEGIN
        RAISERROR(N'Table fact.balance absente. Exécuter au préalable sql/02_schema_fact.sql.', 16, 1);
        RETURN;
    END;
    IF OBJECT_ID('fact.grand_livre', 'U') IS NULL
    BEGIN
        RAISERROR(N'Table fact.grand_livre absente. Exécuter au préalable sql/02_schema_fact.sql.', 16, 1);
        RETURN;
    END;
    IF @exercice_id IS NULL
    BEGIN
        RAISERROR(N'exercice_id est requis.', 16, 1);
        RETURN;
    END;

    DECLARE @execution UNIQUEIDENTIFIER = COALESCE(@execution_id, NEWID());

    DECLARE @total_debit_balance  DECIMAL(19,4) = 0;
    DECLARE @total_credit_balance DECIMAL(19,4) = 0;
    DECLARE @total_debit_gl       DECIMAL(19,4) = 0;
    DECLARE @total_credit_gl      DECIMAL(19,4) = 0;

    SELECT
        @total_debit_balance  = COALESCE(SUM(debit), 0),
        @total_credit_balance = COALESCE(SUM(credit), 0)
    FROM fact.balance
    WHERE exercice_id = @exercice_id;

    SELECT
        @total_debit_gl  = COALESCE(SUM(debit), 0),
        @total_credit_gl = COALESCE(SUM(credit), 0)
    FROM fact.grand_livre
    WHERE exercice_id = @exercice_id;

    DECLARE @ecart_debit  DECIMAL(19,4) = @total_debit_balance  - @total_debit_gl;
    DECLARE @ecart_credit DECIMAL(19,4) = @total_credit_balance - @total_credit_gl;
    DECLARE @net_balance  DECIMAL(19,4) = @total_debit_balance  - @total_credit_balance;
    DECLARE @net_gl       DECIMAL(19,4) = @total_debit_gl       - @total_credit_gl;
    DECLARE @ecart_net    DECIMAL(19,4) = @net_balance - @net_gl;

    DECLARE @status NVARCHAR(30) = CASE WHEN @ecart_debit = 0 AND @ecart_credit = 0 THEN N'OK' ELSE N'À analyser' END;
    DECLARE @summary NVARCHAR(1000) =
        N'balance: debit=' + CONVERT(NVARCHAR(50), @total_debit_balance)
        + N', credit=' + CONVERT(NVARCHAR(50), @total_credit_balance)
        + N'; gl: debit=' + CONVERT(NVARCHAR(50), @total_debit_gl)
        + N', credit=' + CONVERT(NVARCHAR(50), @total_credit_gl)
        + N'; ecart_debit=' + CONVERT(NVARCHAR(50), @ecart_debit)
        + N'; ecart_credit=' + CONVERT(NVARCHAR(50), @ecart_credit)
        + N'; ecart_net=' + CONVERT(NVARCHAR(50), @ecart_net)
        + N'; metric=' + CONVERT(NVARCHAR(50), (ABS(@ecart_debit) + ABS(@ecart_credit)));

    INSERT INTO fact.controles (
        exercice_id,
        control_code,
        executed_at,
        execution_id,
        status,
        result_summary,
        metric_value,
        threshold_hint,
        requires_comment,
        is_overridden,
        created_at,
        created_by,
        modified_at,
        modified_by,
        is_active
    )
    VALUES (
        @exercice_id,
        N'MVP_CTRL_BALANCE_VS_GL',
        SYSUTCDATETIME(),
        @execution,
        @status,
        @summary,
        (ABS(@ecart_debit) + ABS(@ecart_credit)),
        NULL,
        1,
        0,
        SYSUTCDATETIME(),
        @created_by,
        NULL,
        NULL,
        1
    );

    -- Restitution factuelle
    SELECT
        @total_debit_balance  AS total_debit_balance,
        @total_credit_balance AS total_credit_balance,
        @total_debit_gl       AS total_debit_gl,
        @total_credit_gl      AS total_credit_gl,
        @ecart_debit          AS ecart_debit,
        @ecart_credit         AS ecart_credit,
        @ecart_net            AS ecart_net,
        @status               AS status_indicatif;
END;
