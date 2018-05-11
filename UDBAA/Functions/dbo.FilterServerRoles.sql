SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[FilterServerRoles]
(
    @domainName nvarchar(64) = ''
)
RETURNS table
AS
RETURN
(
    SELECT DomainName
         , RoleName
         , IsActive
         , DENSE_RANK() OVER (PARTITION BY RoleName
                              ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
                                     , DomainName DESC
                             )                   AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY RoleName) AS PriorityGroup
    FROM dbo.ServerRoles
    WHERE 1 = 1
          AND DomainName IN ( '', @domainName)
);
GO
