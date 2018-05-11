SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[FilterServerPermissions]
(
    @domainName nvarchar(64) = ''
  , @serverName nvarchar(64) = ''
)
RETURNS table
AS
RETURN
(
    SELECT DomainName
         , ServerName
         , Persona
         , Permission
         , IsActive
         , DENSE_RANK() OVER (PARTITION BY Persona
                                         , Permission
                              ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
                                     , ServerName DESC
                                     , DomainName DESC
                             )                              AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY Persona, Permission) AS PriorityGroup
    FROM dbo.ServerPermissions
    WHERE 1 = 1
          AND DomainName IN ( '', DEFAULT_DOMAIN())
          AND ServerName IN ( '', @@SERVERNAME )
);
GO
