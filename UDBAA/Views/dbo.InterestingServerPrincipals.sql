SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[InterestingServerPrincipals]
AS
SELECT *
FROM sys.server_principals AS m
WHERE 1 = 1
      --AND LEN(r.sid) > 1
      AND m.is_disabled = 0
      AND LEN(m.sid) > 1
      AND m.name NOT LIKE '##MS%'
      AND
      (
          m.name NOT LIKE 'NT SERVICE\%'
          OR m.type NOT IN ( 'U', 'G' )
      )
      AND
      (
          m.name NOT LIKE 'NT AUTHORITY\%'
          OR m.type NOT IN ( 'U', 'G' )
      )
      --AND
      --(
      --    m.name LIKE (DEFAULT_DOMAIN() + '\%')
      --    OR m.type NOT IN ( 'U', 'G' )
      --)
      AND
      (
          m.name != 'distributor_admin'
          OR m.type NOT IN ( 'S' )
      );
GO
