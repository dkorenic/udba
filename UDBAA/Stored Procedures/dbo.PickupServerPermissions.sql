SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PickupServerPermissions]
    --, @domain nvarchar(64) = NULL
    --, @server nvarchar(64) = NULL
    @debug tinyint = 0
  , @print tinyint = 0
  , @dryRun bit = 0
AS
SET NOCOUNT ON;

DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
SET CONTEXT_INFO @ctx;

WITH l AS (
    SELECT *
    FROM dbo.FilteredLogins
    WHERE PriorityRank = 1
)
   , r AS (
    SELECT *
    FROM dbo.FilteredServerRoles
    WHERE PriorityRank = 1
)
   , s AS (
    SELECT sp.class_desc
         , sp.major_id
         , CASE sp.class_desc
               WHEN 'SERVER_PRINCIPAL' THEN
               (
                   SELECT IIF(type = 'R', 'SERVER ROLE', 'LOGIN') + '::' + QUOTENAME(name)
                   FROM sys.server_principals
                   WHERE principal_id = sp.major_id
               )
               WHEN 'ENDPOINT' THEN
               (
                   SELECT 'ENDPOINT::' + QUOTENAME(name) FROM sys.endpoints WHERE endpoint_id = sp.major_id
               )
           END                             AS target
         , sp.grantee_principal_id
         , sp.grantor_principal_id
         , sp.permission_name              AS Permission
         , sp.state                        AS State
         ------
         , p.name
         , p.principal_id
         , p.type_desc
         , p.is_fixed_role
         --
         --, l.Persona
         --, l.LoginName
         --, r.RoleName
         --
         , COALESCE(l.Persona, r.RoleName) AS Persona
    FROM sys.server_permissions    AS sp
        JOIN sys.server_principals AS p
            ON p.principal_id = sp.grantee_principal_id
        LEFT JOIN l
            ON l.LoginName = p.name
        LEFT JOIN r
            ON r.RoleName = p.name
    WHERE 1 = 1
          AND COALESCE(l.Persona, r.RoleName) IS NOT NULL
          AND 'RSUG' LIKE CONCAT('%', p.type, '%')
          --AND p.NAME LIKE @loginLike
          --AND p.is_disabled = 0
          AND LEN(p.sid) > 1
          AND p.name NOT LIKE '##MS%'
          AND
          (
              p.name NOT LIKE 'NT SERVICE\%'
              OR p.type NOT IN ( 'U', 'G' )
          )
          AND
          (
              p.name NOT LIKE 'NT AUTHORITY\%'
              OR p.type NOT IN ( 'U', 'G' )
          )
          --AND
          --(
          --    p.NAME LIKE (DEFAULT_DOMAIN() + '\%')
          --    OR p.TYPE NOT IN ( 'U', 'G' )
          --)
          AND
          (
              p.name != 'distributor_admin'
              OR p.type NOT IN ( 'S' )
          )
)
SELECT DEFAULT_DOMAIN()                              AS DomainName
     , @@SERVERNAME                                  AS ServerName
     , ISNULL(s.target COLLATE DATABASE_DEFAULT, '') AS Target
     --, s.grantee_principal_id
     --, s.grantor_principal_id
     , s.Permission COLLATE DATABASE_DEFAULT         AS Permission
     , s.State COLLATE DATABASE_DEFAULT              AS State
     --, s.name
     --, s.principal_id
     --, s.type_desc
     --, s.is_fixed_role
     , s.Persona
INTO #PiSePe
FROM s;



IF @debug > 1
    SELECT s.*
         , d.*
    FROM #PiSePe                                                             AS s
        LEFT JOIN
        (SELECT * FROM dbo.FilteredServerPermissions WHERE PriorityRank = 1) AS d
            ON 1 = 1
               AND d.Persona = s.Persona
               AND d.Target = s.Target
               AND d.Permission = s.Permission
               AND d.State = s.State;

--EXEC tempdb.sys.sp_help '#PiSePe';

DECLARE @sDomainName  nvarchar(64)
      , @sServerName  nvarchar(64)
      , @sTarget      nvarchar(64) = ''
      , @sPersona     nvarchar(64) = ''
      , @sPermission  nvarchar(64) = ''
      , @sState       char(1)      = ''
      --
      , @dDomainName  nvarchar(64)
      , @dServerName  nvarchar(64)
      , @dTarget      nvarchar(64)
      , @dPersona     nvarchar(64)
      , @dPermission  nvarchar(64)
      , @dState       char(1)
      --
      , @d2DomainName nvarchar(64)
      , @d2ServerName nvarchar(64)
      , @d2Target     nvarchar(64)
      , @d2Persona    nvarchar(64)
      , @d2Permission nvarchar(64)
      , @d2State      char(1);


WHILE 1 = 1
BEGIN
    WITH s AS (
        SELECT *
        FROM #PiSePe
    )
       , d AS (
        SELECT *
        FROM dbo.FilteredServerPermissions
        WHERE PriorityRank = 1
    )
       , d2 AS (
        SELECT *
        FROM dbo.FilteredServerPermissions
        WHERE DomainName != ''
              AND ServerName != ''
    )
    SELECT TOP 1
        @sDomainName  = s.DomainName
      , @sServerName  = s.ServerName
      , @sTarget      = s.Target
      , @sPersona     = s.Persona
      , @sPermission  = s.Permission
      , @sState       = s.State
      --
      , @dDomainName  = d.DomainName
      , @dServerName  = d.ServerName
      , @dTarget      = d.Target
      , @dPersona     = d.Persona
      , @dPermission  = d.Permission
      , @dState       = d.State
      --
      , @d2DomainName = d2.DomainName
      , @d2ServerName = d2.ServerName
      , @d2Target     = d2.Target
      , @d2Persona    = d2.Persona
      , @d2Permission = d2.Permission
      , @d2State      = d2.State
    FROM s
        LEFT JOIN d
            ON 1 = 1
               AND d.Target = s.Target
               AND d.Persona = s.Persona
               AND d.Permission = s.Permission
               AND d.State = s.State
        LEFT JOIN d2
            ON 1 = 1
               AND d2.Target = s.Target
               AND d2.Persona = s.Persona
               AND d2.Permission = s.Permission
               AND d2.State = s.State
    WHERE (
              s.Persona > @sPersona
              OR
              (
                  s.Persona = @sPersona
                  AND s.Permission > @sPermission
              )
              OR
              (
                  s.Persona = @sPersona
                  AND s.Permission = @sPermission
                  AND s.Target > @sTarget
              )
              OR
              (
                  s.Persona = @sPersona
                  AND s.Permission = @sPermission
                  AND s.Target = @sTarget
                  AND s.State > @sState
              )
          )
          AND (
        -- not in config
        (
            d.Persona IS NULL
            OR @debug > 0
        )
              )
    ORDER BY s.Persona
           , s.Permission
           , s.Target
           , s.State;
    IF @@ROWCOUNT = 0
        BREAK;

    IF @print > 0
    BEGIN

        PRINT CONCAT('@sDomainName					= ', @sDomainName);
        PRINT CONCAT('@dDomainName					= ', @dDomainName);
        PRINT CONCAT('@d2DomainName					= ', @d2DomainName);

        PRINT CONCAT('@sServerName					= ', @sServerName);
        PRINT CONCAT('@dServerName					= ', @dServerName);
        PRINT CONCAT('@d2ServerName					= ', @d2ServerName);

        PRINT CONCAT('@sPersona						= ', @sPersona);
        PRINT CONCAT('@dPersona						= ', @dPersona);
        PRINT CONCAT('@d2Persona						= ', @d2Persona);

        PRINT CONCAT('@sPermission					= ', @sPermission);
        PRINT CONCAT('@dPermission					= ', @dPermission);
        PRINT CONCAT('@d2Permission					= ', @d2Permission);

        PRINT CONCAT('@sTarget						= ', @sTarget);
        PRINT CONCAT('@dTarget						= ', @dTarget);
        PRINT CONCAT('@d2Target						= ', @d2Target);

        PRINT CONCAT('@sState							= ', @sState);
        PRINT CONCAT('@dState							= ', @dState);
        PRINT CONCAT('@d2State						= ', @d2State);

        PRINT '';

    END;



    -- not in cofig
    IF @dPersona IS NULL
    BEGIN
        PRINT CONCAT('Inserting ', CASE @sState WHEN 'D' THEN 'DENY' WHEN 'G' THEN 'GRANT' END, ' ', @sPermission, ' ON ' + NULLIF(@sTarget, ''), ' FOR ', QUOTENAME(@sPersona));

        IF @dryRun = 0
            INSERT INTO dbo.ServerPermissions
            (
                DomainName
              , ServerName
              , Persona
              , Permission
              , Target
              , State
              , IsActive
            )
            VALUES
            (@sDomainName, @sServerName, @sPersona, @sPermission, @sTarget, @sState, NULL);

    END;
    ELSE
    -- inače odjeb
    BEGIN
        PRINT 'Skipping!';
    END;

    PRINT '';
END;


GO
