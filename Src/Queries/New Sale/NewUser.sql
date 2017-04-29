
DECLARE  @UserID AS INT
EXECUTE   [dbo].[sp_User_Insert] 
   '921378'
  ,'921378'
  ,'نسرین'
  ,'سواری'
  ,''
  ,''
  ,@UserID OUTPUT
 

 INSERT INTO dbo.PrgAccess
         ( UserID ,
           ProgramID ,
           AccessTypeID ,
           CheckComputerAndLogin
         )
 VALUES  (@UserID , -- UserID - int
           2 , -- ProgramID - smallint
           255 , -- AccessTypeID - tinyint
           0  -- CheckComputerAndLogin - tinyint
         )

		 INSERT INTO dbo.UsersInRoles
		         ( UserID, ProgramID, RoleID )
		 VALUES  ( @UserID, -- UserID - int
		           2, -- ProgramID - smallint
		           5  -- RoleID - smallint
		           )

 

