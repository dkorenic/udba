SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PickupLogins]
    @loginLike sysname = '%'
  , @types nvarchar(16) = 'SUG'
  --, @domain nvarchar(64) = NULL
  --, @server nvarchar(64) = NULL
  , @debug tinyint = 0
  , @print tinyint = 0
  , @dryRun bit = 0
AS
SET NOCOUNT ON;

DECLARE @ctx varbinary(128) = CAST(OBJECT_NAME(@@PROCID) AS varbinary(128));
SET CONTEXT_INFO @ctx;

WITH s AS (
    SELECT DEFAULT_DOMAIN()                                                                  AS DomainName
         , @@SERVERNAME                                                                      AS ServerName
         , IIF(p.TYPE = 'S', p.NAME, SUBSTRING(p.NAME, CHARINDEX('\', p.NAME) + 1, 64))      AS Persona
         , p.NAME COLLATE DATABASE_DEFAULT                                                   AS LoginName
         , p.TYPE COLLATE DATABASE_DEFAULT                                                   AS LoginSystemType
         , CONVERT(varchar(172), IIF(p.TYPE = 'S', p.SID, NULL), 1) COLLATE DATABASE_DEFAULT AS LoginSID
         , pp.PasswordHash                                                                   AS LoginPasswordHash
         , pp.PasswordLastSetTimeUtc                                                         AS LoginPasswordLastSetTimeUtc
    FROM sys.server_principals AS p
        OUTER APPLY
    (
        SELECT CONVERT(varchar(514), CAST(LOGINPROPERTY(p.name, 'PasswordHash') AS varbinary(256)), 1)                                         PasswordHash
             , DATEADD(MINUTE, -DATEDIFF(MINUTE, GETUTCDATE(), GETDATE()), CAST(LOGINPROPERTY(p.NAME, 'PasswordLastSetTime') AS datetime2(3))) PasswordLastSetTimeUtc
        WHERE p.TYPE = 'S'
    )                          pp
    WHERE @types LIKE CONCAT('%', p.TYPE, '%')
          AND p.NAME LIKE @loginLike
          AND is_disabled = 0
          AND LEN(p.SID) > 1
          AND p.NAME NOT LIKE '##MS%'
          AND
          (
              p.NAME NOT LIKE 'NT SERVICE\%'
              OR p.TYPE NOT IN ( 'U', 'G' )
          )
          AND
          (
              p.NAME NOT LIKE 'NT AUTHORITY\%'
              OR p.TYPE NOT IN ( 'U', 'G' )
          )
          --AND
          --(
          --    p.NAME LIKE (DEFAULT_DOMAIN() + '\%')
          --    OR p.TYPE NOT IN ( 'U', 'G' )
          --)
          AND
          (
              p.NAME != 'distributor_admin'
              OR p.TYPE NOT IN ( 'S' )
          )
)
SELECT *
INTO #PiLoLo
FROM s;

IF @debug > 1
    SELECT d.*
         , s.*
    FROM #PiLoLo                                                                                AS s
        FULL OUTER JOIN
        (SELECT * FROM dbo.FilteredLogins WHERE PriorityRank = 1 AND LoginName LIKE @loginLike) AS d
            ON 1 = 1
               AND d.LoginName = s.LoginName;

DECLARE @sLoginName                    sysname = ''
      , @sDomainName                   nvarchar(64)
      , @sServerName                   nvarchar(64)
      , @sPersona                      nvarchar(64)
      , @sLoginSystemType              char(1)
      , @sLoginSID                     varchar(172)
      , @sLoginPasswordHash            varchar(514)
      , @sLoginPasswordLastSetTimeUtc  datetime2(3)
      --
      , @dLoginName                    nvarchar(128)
      , @dDomainName                   nvarchar(64)
      , @dServerName                   nvarchar(64)
      , @dPersona                      nvarchar(64)
      , @dLoginSystemType              char(1)
      , @dLoginSID                     varchar(172)
      , @dLoginPasswordHash            varchar(514)
      , @dLoginPasswordLastSetTimeUtc  datetime2(3)
      --
      , @d2LoginName                   nvarchar(128)
      , @d2DomainName                  nvarchar(64)
      , @d2ServerName                  nvarchar(64)
      , @d2Persona                     nvarchar(64)
      , @d2LoginSystemType             char(1)
      , @d2LoginSID                    varchar(172)
      , @d2LoginPasswordHash           varchar(514)
      , @d2LoginPasswordLastSetTimeUtc datetime2(3);


WHILE 1 = 1
BEGIN
    WITH s AS (
        SELECT *
        FROM #PiLoLo
    )
       , d AS (
        SELECT *
        FROM dbo.FilteredLogins
        WHERE PriorityRank = 1
    )
       , d2 AS (
        SELECT *
        FROM dbo.FilteredLogins
        WHERE DomainName != ''
              AND ServerName != ''
    )
    SELECT TOP 1
        @sLoginName                    = s.LoginName
      , @sDomainName                   = s.DomainName
      , @sServerName                   = s.ServerName
      , @sPersona                      = s.Persona
      , @sLoginSystemType              = s.LoginSystemType
      , @sLoginSID                     = s.LoginSID
      , @sLoginPasswordHash            = s.LoginPasswordHash
      , @sLoginPasswordLastSetTimeUtc  = s.LoginPasswordLastSetTimeUtc
      --
      , @dLoginName                    = d.LoginName
      , @dDomainName                   = d.DomainName
      , @dServerName                   = d.ServerName
      , @dPersona                      = d.Persona
      , @dLoginSystemType              = d.LoginSystemType
      , @dLoginSID                     = d.LoginSID
      , @dLoginPasswordHash            = d.LoginPasswordHash
      , @dLoginPasswordLastSetTimeUtc  = d.LoginPasswordLastSetTimeUtc
      --
      , @d2LoginName                   = d2.LoginName
      , @d2DomainName                  = d2.DomainName
      , @d2ServerName                  = d2.ServerName
      , @d2Persona                     = d2.Persona
      , @d2LoginSystemType             = d2.LoginSystemType
      , @d2LoginSID                    = d2.LoginSID
      , @d2LoginPasswordHash           = d2.LoginPasswordHash
      , @d2LoginPasswordLastSetTimeUtc = d2.LoginPasswordLastSetTimeUtc
    FROM s
        LEFT JOIN d
            ON 1 = 1
               AND d.LoginName = s.LoginName
        LEFT JOIN d2
            ON 1 = 1
               AND d2.LoginName = s.LoginName
    WHERE s.LoginName > @sLoginName
          AND
          (
              -- no login in config
              (d.LoginName IS NULL)
              -- password different and older than in config
              OR
              (
                  s.LoginPasswordHash != d.LoginPasswordHash
                  AND
                  (
                      d.LoginPasswordLastSetTimeUtc < s.LoginPasswordLastSetTimeUtc
                      OR
                      (
                          d.LoginSystemType = 'S'
                          AND d.LoginPasswordLastSetTimeUtc IS NULL
                      )
                  )
              )
          )
    ORDER BY s.LoginName;
    IF @@ROWCOUNT = 0
        BREAK;

    PRINT CONCAT('@sLoginName						= ', @sLoginName);
    PRINT CONCAT('@dLoginName						= ', @dLoginName);
    PRINT CONCAT('@d2LoginName					= ', @d2LoginName);

    PRINT CONCAT('@sDomainName					= ', @sDomainName);
    PRINT CONCAT('@dDomainName					= ', @dDomainName);
    PRINT CONCAT('@d2DomainName					= ', @d2DomainName);

    PRINT CONCAT('@sServerName					= ', @sServerName);
    PRINT CONCAT('@dServerName					= ', @dServerName);
    PRINT CONCAT('@d2ServerName					= ', @d2ServerName);

    PRINT CONCAT('@sPersona						= ', @sPersona);
    PRINT CONCAT('@dPersona						= ', @dPersona);
    PRINT CONCAT('@d2Persona						= ', @d2Persona);

    PRINT CONCAT('@sLoginSystemType				= ', @sLoginSystemType);
    PRINT CONCAT('@dLoginSystemType				= ', @dLoginSystemType);
    PRINT CONCAT('@d2LoginSystemType				= ', @d2LoginSystemType);

    PRINT CONCAT('@sLoginSID						= ', @sLoginSID);
    PRINT CONCAT('@dLoginSID						= ', @dLoginSID);
    PRINT CONCAT('@d2LoginSID						= ', @d2LoginSID);

    PRINT CONCAT('@sLoginPasswordHash				= ', @sLoginPasswordHash);
    PRINT CONCAT('@dLoginPasswordHash				= ', @dLoginPasswordHash);
    PRINT CONCAT('@d2LoginPasswordHash			= ', @d2LoginPasswordHash);

    PRINT CONCAT('@sLoginPasswordLastSetTimeUtc	= ', @sLoginPasswordLastSetTimeUtc);
    PRINT CONCAT('@dLoginPasswordLastSetTimeUtc	= ', @dLoginPasswordLastSetTimeUtc);
    PRINT CONCAT('@d2LoginPasswordLastSetTimeUtc	= ', @d2LoginPasswordLastSetTimeUtc);

    PRINT '';

    -- fali u configu
    IF @dLoginName IS NULL
    BEGIN
        PRINT CONCAT('Inserting ', QUOTENAME(@sLoginName));

        IF @dryRun = 0
            INSERT INTO dbo.Logins
            (
                DomainName
              , ServerName
              , Persona
              , LoginName
              , LoginSystemType
              , LoginSID
              , LoginPasswordHash
              , LoginPasswordLastSetTimeUtc
              , IsActive
            )
            VALUES
            (@sDomainName, @sServerName, @sPersona, @sLoginName, @sLoginSystemType, @sLoginSID, @sLoginPasswordHash, @sLoginPasswordLastSetTimeUtc, NULL);
    END;
    ELSE
    -- noviji password na stroju
    IF @sLoginPasswordLastSetTimeUtc > @dLoginPasswordLastSetTimeUtc
       AND @sLoginPasswordHash != @dLoginPasswordHash
    BEGIN
        PRINT CONCAT('Updating to ', QUOTENAME(@sLoginName), ' to new password.');

        IF @dryRun = 0
            UPDATE dbo.FilteredLogins
            SET LoginPasswordHash = @sLoginPasswordHash
              , LoginPasswordLastSetTimeUtc = @sLoginPasswordLastSetTimeUtc
            WHERE LoginName = @sLoginName;
    END;
    ELSE
    -- inače odjeb
    BEGIN
        PRINT 'Skipping!';
    END;

    PRINT '';
END;

GO
