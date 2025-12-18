-- Contrôle mécanique NEP 2300 : équilibre global débit/crédit pour un exercice (aucune conclusion automatique)
-- Entrées :
--   @exercice_id   UNIQUEIDENTIFIER (obligatoire)
--   @execution_id  UNIQUEIDENTIFIER (optionnel, généré si NULL)
--   @data_source   NVARCHAR(20) = 'auto' | 'fec' | 'gl' | 'balance' (défaut 'auto')
--   @created_by    NVARCHAR(100) = 'system' par défaut
-- Sortie : insertion d'une ligne dans fact.controles avec un statut indicatif et un résumé factuel.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fact')
BEGIN
    EXEC('CREATE SCHEMA fact');
END;

CREATE OR ALTER PROCEDURE fact.usp_ctrl_equilibre_debit_credit
    @exercice_id  UNIQUEIDENTIFIER,
    @execution_id UNIQUEIDENTIFIER = NULL,
    @data_source  NVARCHAR(20) = N'auto',
    @created_by   NVARCHAR(100) = N'system'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validation des tables cibles (schéma fact requis)
    IF OBJECT_ID('fact.controles', 'U') IS NULL
    BEGIN
        RAISERROR(N'Table fact.controles absente. Exécuter au préalable sql/02_schema_fact.sql.', 16, 1);
        RETURN;
    END;

    IF @exercice_id IS NULL
    BEGIN
        RAISERROR(N'exercice_id est requis.', 16, 1);
        RETURN;
    END;

    DECLARE @src NVARCHAR(20) = LOWER(COALESCE(@data_source, N'auto'));
    IF @src NOT IN (N'auto', N'fec', N'gl', N'balance')
    BEGIN
        RAISERROR(N'data_source invalide. Valeurs autorisées : auto | fec | gl | balance.', 16, 1);
        RETURN;
    END;

    DECLARE @has_fec_table BIT = CASE WHEN OBJECT_ID('fact.fec_ecritures', 'U') IS NOT NULL THEN 1 ELSE 0 END;
    DECLARE @has_gl_table  BIT = CASE WHEN OBJECT_ID('fact.grand_livre',   'U') IS NOT NULL THEN 1 ELSE 0 END;
    DECLARE @has_bal_table BIT = CASE WHEN OBJECT_ID('fact.balance',       'U') IS NOT NULL THEN 1 ELSE 0 END;

    IF @src = N'fec' AND @has_fec_table = 0
    BEGIN
        RAISERROR(N"Table fact.fec_ecritures absente pour data_source='fec'.", 16, 1);
        RETURN;
    END;
    IF @src = N'gl' AND @has_gl_table = 0
    BEGIN
        RAISERROR(N"Table fact.grand_livre absente pour data_source='gl'.", 16, 1);
        RETURN;
    END;
    IF @src = N'balance' AND @has_bal_table = 0
    BEGIN
        RAISERROR(N"Table fact.balance absente pour data_source='balance'.", 16, 1);
        RETURN;
    END;

    IF @exercice_id IS NULL
    BEGIN
        RAISERROR(N'exercice_id est requis.', 16, 1);
        RETURN;
    END;

    DECLARE @execution UNIQUEIDENTIFIER = COALESCE(@execution_id, NEWID());

    DECLARE @use_fec BIT = CASE WHEN @src = N'fec' THEN 1 ELSE 0 END;
    DECLARE @use_gl  BIT = CASE WHEN @src = N'gl' THEN 1 ELSE 0 END;
    DECLARE @use_bal BIT = CASE WHEN @src = N'balance' THEN 1 ELSE 0 END;

    IF @src = N'auto'
    BEGIN
        SET @use_fec = CASE WHEN @has_fec_table = 1 AND EXISTS (SELECT 1 FROM fact.fec_ecritures WHERE exercice_id = @exercice_id) THEN 1 ELSE 0 END;
        SET @use_gl  = CASE WHEN @has_gl_table = 1 AND @use_fec = 0 AND EXISTS (SELECT 1 FROM fact.grand_livre WHERE exercice_id = @exercice_id) THEN 1 ELSE 0 END;
        SET @use_bal = CASE WHEN @has_bal_table = 1 AND @use_fec = 0 AND @use_gl = 0 THEN 1 ELSE 0 END;

        -- Si aucune source dispo, lever une erreur explicite
        IF @use_fec = 0 AND @use_gl = 0 AND @use_bal = 0
        BEGIN
            RAISERROR(N'Aucune source disponible (fec, grand_livre, balance) pour l''exercice fourni.', 16, 1);
            RETURN;
        END;
    END;

    DECLARE @total_debit DECIMAL(19,4) = 0;
    DECLARE @total_credit DECIMAL(19,4) = 0;
    DECLARE @source_used NVARCHAR(20) = NULL;

    IF @use_fec = 1
    BEGIN
        SELECT
            @total_debit  = COALESCE(SUM(debit), 0),
            @total_credit = COALESCE(SUM(credit), 0)
        FROM fact.fec_ecritures
        WHERE exercice_id = @exercice_id;
        SET @source_used = N'fec';
    END
    ELSE IF @use_gl = 1
    BEGIN
        SELECT
            @total_debit  = COALESCE(SUM(debit), 0),
            @total_credit = COALESCE(SUM(credit), 0)
        FROM fact.grand_livre
        WHERE exercice_id = @exercice_id;
        SET @source_used = N'gl';
    END
    ELSE
    BEGIN
        SELECT
            @total_debit  = COALESCE(SUM(debit), 0),
            @total_credit = COALESCE(SUM(credit), 0)
        FROM fact.balance
        WHERE exercice_id = @exercice_id;
        SET @source_used = N'balance';
    END;

    DECLARE @ecart DECIMAL(19,4) = @total_debit - @total_credit;
    DECLARE @status NVARCHAR(30) = CASE WHEN @ecart = 0 THEN N'OK' ELSE N'À analyser' END;
    DECLARE @summary NVARCHAR(1000) =
        N'Source=' + @source_used
        + N'; total_debit=' + CONVERT(NVARCHAR(50), @total_debit)
        + N'; total_credit=' + CONVERT(NVARCHAR(50), @total_credit)
        + N'; ecart=' + CONVERT(NVARCHAR(50), @ecart);

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
        N'MVP_CTRL_EQ_DC',
        SYSUTCDATETIME(),
        @execution,
        @status,
        @summary,
        ABS(@ecart),
        NULL,
        1,
        0,
        SYSUTCDATETIME(),
        @created_by,
        NULL,
        NULL,
        1
    );
END;
