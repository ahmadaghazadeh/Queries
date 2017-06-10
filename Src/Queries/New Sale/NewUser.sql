USE [UsersManagements]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Insert]    Script Date: 6/10/2017 8:29:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_User_Insert]
	@UserName NVARCHAR(50),
	@EmployeeId VARCHAR(6),
	@FirstName NVARCHAR(25),
	@LastName NVARCHAR(35),
	@SystemUserName VARCHAR(50),
	@SystemComputerName VARCHAR(50),
	@UserID INT OUTPUT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION T1
		
		 
		
		INSERT INTO Users
		  (
		    UserID,
		    UserName,
		    UserPass,
		    EmployeeId,
		    FirstName,
		    LastName,
		    SystemUserName,
		    SystemComputerName,
		    UserCategoryID,
		    UserGroupId
		  )
		VALUES
		  (
		    @UserID,
		    LTRIM(RTRIM(LOWER(@UserName))),
		    (
		        SELECT e.DefaultUserPassword
		        FROM   Extra e
		    ),
		    @EmployeeId,
		    LTRIM(RTRIM(@FirstName)),
		    LTRIM(RTRIM(@LastName)),
		    LTRIM(RTRIM(LOWER(@SystemUserName))),
		    LTRIM(RTRIM(LOWER(@SystemComputerName))),
		    2,
		    1
		  ) 
		
		COMMIT TRANSACTION T1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION T1
		
		DECLARE @ErrMsg  NVARCHAR(2048),
		        @ErrSvr  INT,
		        @ErrStt  INT
		
		SELECT @ErrMsg = 'PROCEDURE: ' +
		       ERROR_PROCEDURE() + ', LINE:' + CONVERT(VARCHAR, ERROR_LINE()) +
		       ', ' +
		       ERROR_MESSAGE(),
		       @ErrSvr = ERROR_SEVERITY(),
		       @ErrStt = ERROR_STATE()
		
		RAISERROR (@ErrMsg, @ErrSvr, @ErrStt)
	END CATCH
END





