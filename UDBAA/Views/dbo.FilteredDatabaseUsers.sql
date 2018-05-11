SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[FilteredDatabaseUsers]
AS
WITH du AS (
    SELECT du.DomainName
         , du.ServerName
         , du.Tennant
         , du.DatabaseTypeCode
         , du.DatabaseName
         , du.Persona
         , du.IsActive
    FROM dbo.DatabaseUsers AS du
    WHERE 1 = 1
          AND du.DomainName IN ( '', DEFAULT_DOMAIN())
          AND ServerName IN ( '', @@SERVERNAME )
)
   , d AS (
    SELECT DomainName
         , ServerName
         , DatabaseName
         , DatabaseTypeCode
         , Tennant
    FROM dbo.Databases
    WHERE 1 = 1
          AND DomainName IN ( '', DEFAULT_DOMAIN())
          AND ServerName IN ( '', @@SERVERNAME )
)
   , j AS (
    SELECT du.IsActive
         --
         , d.DatabaseName      [d.DatabaseName]
         , d.Tennant           [d.Tennant]
         , d.DatabaseTypeCode  [d.DatabaseTypeCode]
         --
         , du.DomainName       [du.DomainName]
         , du.ServerName       [du.ServerName]
         , du.DatabaseName     [du.DatabaseName]
         , du.Tennant          [du.Tennant]
         , du.DatabaseTypeCode [du.DatabaseTypeCode]
         , du.Persona          [du.Persona]
    FROM du
        JOIN d
            ON 1 = 1
               AND (du.DatabaseName IN ( '', d.DatabaseName ))
               AND (du.DatabaseTypeCode IN ( '', d.DatabaseTypeCode ))
               AND (du.Tennant IN ( '', d.Tennant ))
)
   , s AS (
    SELECT [du.DomainName]                                             DomainName
         , [du.ServerName]                                             ServerName
         , [du.Tennant]                                                Tennant
         , [du.DatabaseTypeCode]                                       DatabaseTypeCode
         , [d.DatabaseName]                                            DatabaseName
         , [du.Persona]                                                Persona
         , IsActive
         --, *
         --, RANK() OVER (PARTITION BY [d.DatabaseName]
         --                          , [du.Persona]
         --               ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
         --              )                                               AS RANK
         , DENSE_RANK() OVER (PARTITION BY [d.DatabaseName]
                                         , [du.Persona]
                              ORDER BY CASE WHEN IsActive = 0 THEN 1 WHEN IsActive = 1 THEN 2 ELSE 3 END
                                     , [du.DatabaseName] DESC
                                     , [du.DatabaseTypeCode] DESC
                                     , [du.Tennant] DESC
                                     , [du.ServerName] DESC
                                     , [du.DomainName] DESC
                             )                                         AS PriorityRank
         , DENSE_RANK() OVER (ORDER BY [d.DatabaseName], [du.Persona]) AS PriorityGroup
    FROM j
)
SELECT *
FROM s
--WHERE PRIORITY = 1;
;
GO
