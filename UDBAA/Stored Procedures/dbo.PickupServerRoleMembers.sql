SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PickupServerRoleMembers]
    @roleLike sysname = '%'
  --, @debug tinyint = 2
  , @print tinyint = 0
  , @dryRun bit = 0
AS
SET NOCOUNT ON;

DECLARE @roleName nvarchar(64) = ''
      , @persona  nvarchar(64) = '';

WHILE 1 = 1
BEGIN
    SELECT TOP 1
        @roleName = r.name
      , @persona  = fl.Persona
    FROM sys.server_role_members   AS srm
        JOIN sys.server_principals AS r
            ON srm.role_principal_id = r.principal_id
        JOIN sys.server_principals AS p
            ON srm.member_principal_id = p.principal_id
        JOIN dbo.FilteredLogins    AS fl
            ON p.name = fl.LoginName
    WHERE r.name LIKE @roleLike
          AND NOT EXISTS
    (
        SELECT *
        FROM dbo.FilteredServerRoleMembers AS fsrm
        WHERE fsrm.Persona = fl.Persona
              AND fsrm.RoleName = r.name
              AND fsrm.IsActive IS NOT NULL
    )
          AND NOT EXISTS
    (
        SELECT *
        FROM dbo.ServerRoleMembers AS csrm
        WHERE csrm.Persona = fl.Persona
              AND csrm.RoleName = r.name
              AND csrm.DomainName = DEFAULT_DOMAIN()
              AND csrm.ServerName = @@SERVERNAME
    )
          AND
          (
              @roleName < r.name
              OR
              (
                  @roleName = r.name
                  AND @persona < fl.Persona
              )
          )
    ORDER BY r.name
           , fl.Persona;
    IF @@ROWCOUNT = 0
        BREAK;

    IF @print > 0
        PRINT CONCAT(@persona, ' -> ', @roleName);

    IF @dryRun = 0
        INSERT INTO dbo.ServerRoleMembers
        (
            DomainName
          , ServerName
          , RoleName
          , Persona
          , IsActive
        )
        VALUES
        (DEFAULT_DOMAIN(), @@SERVERNAME, @roleName, @persona, NULL);

END;


GO
