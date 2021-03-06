﻿ 
  

  
INSERT  INTO [dbo].[BranchSettings]
        ( [Key], [Value] )
VALUES  ( 'faraPayamakNumber', '200095341263' );

GO

INSERT  INTO [dbo].[BranchSettings]
        ( [Key], [Value] )
VALUES  ( 'faraPayamakPassword', 'Dbcoshiraz94#' );

GO

INSERT  INTO [dbo].[BranchSettings]
        ( [Key], [Value] )
VALUES  ( 'faraPayamakUserName', 'dbcoshiraz' );

 GO



ALTER FUNCTION [dbo].[udft_Employee]
						(@RunDate VARCHAR(25))
						RETURNS TABLE 
						AS
						RETURN
						(
							WITH MyCTE AS
							(
								SELECT EmployeeID , EmployeeTypeID, MAX(RunDate) RunDate
								FROM dbo.[Employee]
								WHERE RunDate <= @RunDate
								GROUP BY EmployeeID , EmployeeTypeID 
							)
							SELECT [Employee].*
							FROM dbo.Employee
							INNER JOIN MyCTE ON Employee.EmployeeID = MyCTE.EmployeeID AND Employee.EmployeeTypeID = MyCTE.EmployeeTypeID AND Employee.RunDate = MyCTE.RunDate AND IsDeleted = 0
						)


GO


 
-- =============================================
-- Author:		Ahmad Aghazadeh
-- Create date: 1395/07/24
-- Description:	Check employee can invoiceIssue
-- =============================================
ALTER PROCEDURE sp_canInvoiceIssue 
	@EmployeeID int = 0 
AS
BEGIN
	 SELECT ISNULL(ue.CanInvoiceIssue,0) CanInvoiceIssue, ISNULL(ue.WHCode,0) WHCode FROM dbo.udft_Employee('2') ue WHERE EmployeeID=@EmployeeID
END
GO
 
 
ALTER PROCEDURE [dbo].[sp_Invoice_Issue_Salesman]
    @OrderNo BIGINT ,
    @EmployeeID BIGINT  
AS
    BEGIN  
        SET NOCOUNT ON; 
		
		 
        DECLARE @RegDate CHAR(10)= dbo.fn_GetPersianDate(GETDATE());
        DECLARE @UserID INT;
        DECLARE @IsManual BIT= 0;
        DECLARE @Comment NVARCHAR(MAX)= '';
        DECLARE @Result TINYINT;
        DECLARE @BusinessDocNo BIGINT;
        DECLARE @RunDate VARCHAR(25)= dbo.fn_GetPersianDateTime(GETDATE());
		DECLARE @response AS NVARCHAR(4000);
        SELECT  @UserID = UserID
        FROM    dbo.vw_User
        WHERE   EmployeeId = @EmployeeID;
	
        IF @UserID IS NULL
            BEGIN
                SET @response = N'خطا!' + CHAR(13)
                    + N'شماره يا پرسنل شناسايي نشد';
            
                RAISERROR(@response ,18 ,1);
            END;
     
        BEGIN TRY
            BEGIN TRANSACTION;

            EXECUTE [dbo].[sp_Invoice_Issue] @OrderNo, @RegDate, @UserID,
                @IsManual, @Comment, @Result OUTPUT, @BusinessDocNo OUTPUT,
                @RunDate;

            IF ( @Result = 0 )
                BEGIN
                    EXEC dbo.sp_GetBusinessDocJSON @BusinessDocNo = @BusinessDocNo;  
                END;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF ( @@TRANCOUNT > 0 )
                ROLLBACK TRANSACTION;

		    EXEC dbo.sp_Order_Delete @OrderNo ,  @RunDate, @UserID  
		    
            EXEC UsersManagements.dbo.sp_CatchError @RaisError = 1,
                @ExtraData = NULL, @ErrorId = NULL;
        END CATCH;
    END;  
  
  


  Go
  
  
  
  

  
ALTER PROCEDURE [dbo].[sp_GetBusinessDocJSON]  
    @BusinessDocNo BIGINT    
AS  
    BEGIN  
        BEGIN TRY  
            BEGIN TRANSACTION T1;  
         
            DECLARE @BranchName AS NVARCHAR(50);  
            DECLARE @CustomerId AS INTEGER;  
            DECLARE @PersonID AS INTEGER;  
            DECLARE @OrderId BIGINT;   
            DECLARE @CustomerIds AS NVARCHAR(MAX);  
            DECLARE @CusmtomerName AS NVARCHAR(MAX);  
            DECLARE @CusmtomerMobile AS NVARCHAR(MAX);  
            DECLARE @FactorId AS NVARCHAR(MAX);  
            DECLARE @Body AS NVARCHAR(MAX);  
            DECLARE @Details AS NVARCHAR(MAX);  
            DECLARE @Retrun AS NVARCHAR(MAX);  
            DECLARE @Discount AS NVARCHAR(MAX);  
            DECLARE @Additions AS NVARCHAR(MAX);  
            DECLARE @PayableDiscription AS NVARCHAR(MAX);  
            DECLARE @PayableLetters AS NVARCHAR(MAX);  
            DECLARE @Date AS NVARCHAR(10);  
            DECLARE @VisitorName AS NVARCHAR(50);  
            DECLARE @VisitorMobile AS NVARCHAR(20);  
            DECLARE @Weight AS NVARCHAR(20);  
            DECLARE @CartonCount AS NVARCHAR(50);  
            DECLARE @PacketCount AS NVARCHAR(20);  
            DECLARE @TotalPrice AS NUMERIC(15, 0);   
            DECLARE @Payable AS NUMERIC(15, 0);   
            DECLARE @TotalDiscount AS NUMERIC(15, 0);   
            DECLARE @TotalAdditions AS NUMERIC(15, 0);   
            DECLARE @DiscountPecuniary AS NUMERIC(15, 0);   
            DECLARE @DiscountPecuniaryPercent AS DECIMAL(4, 2);   
            DECLARE @AfterDiscountPecuniary AS NUMERIC(15, 0);   
            DECLARE @PaymentType AS INT;  
  
         
            SELECT  @PaymentType = uo.PaymentTypeID ,  
                    @PersonID = uo.PersonID ,  
                    @VisitorName = LTRIM(RTRIM(ue.EmployeeName)) ,  
                    @VisitorMobile = LTRIM(RTRIM(ue.EmployeeMobile)) ,  
                    @Date = ub.RegDate ,  
                    @OrderId = uo.OrderNo  
            FROM    dbo.udft_Order('2') AS uo  
                    INNER JOIN dbo.udft_Employee('2') AS ue ON uo.VisitorEmployeeID = ue.EmployeeID  
                    INNER JOIN dbo.udft_BusinessDoc('2') ub ON ub.OrderNo = uo.OrderNo  
            WHERE   ub.BusinessDocNo = BusinessDocNo;  
          
            SELECT  @CustomerId = dbo.fn_GetCustomerID(uc.PersonID) ,  
                    @CusmtomerName = uc.PersonName ,  
                    @CusmtomerMobile =CONVERT(BIGINT, uc.CellNo  )
            FROM    dbo.udft_Person('2') AS uc  
            WHERE   uc.PersonID = @PersonID;   
          
          
            SELECT  @BranchName = sb.BranchName  
            FROM    LocalSetting AS ls  
                    INNER JOIN syn_Branchs AS sb ON sb.BranchCode = ls.BranchCode;  
          
   
  
  
            DECLARE @ProductTemp TABLE  
                (  
                  Row INT ,  
                  QTY SMALLINT ,  
                  Price NUMERIC(15, 0) ,  
                  SumPrice NUMERIC(15, 0) ,  
                  Unit NVARCHAR(2) ,  
                  UnitId SMALLINT ,  
                  Reward NVARCHAR(2) ,  
                  ProductName NVARCHAR(50) ,  
                  NetWeight INT ,  
                  IsBonus BIT  
                );  
            INSERT  INTO @ProductTemp  
                    ( Row ,  
                      QTY ,  
                      Price ,  
                      SumPrice ,  
                      Unit ,  
                      UnitId ,  
                      Reward ,  
                      ProductName ,  
                      NetWeight ,  
                      IsBonus  
                    )  
                    SELECT  ( ROW_NUMBER() OVER ( ORDER BY uod.Row ) ) Row ,  
                            uod.Qty ,  
                            CONVERT(INT, ISNULL(ROUND(SaleCore.dbo.GetUnitConversionRate(uod.ProductCode,  
                                                              uod.UnitID,  
                                                              uc.MainUnitID,  
                                          '2')  
                                                      * upld.SalePrice, 1), 0)) Price ,  
                            CONVERT(INT, ISNULL(ROUND(( SaleCore.dbo.GetUnitConversionRate(uod.ProductCode,  
                                                              uod.UnitID,  
                                                              uc.MainUnitID,  
                                                              '2')  
                                                        * upld.SalePrice ), 0),  
                                                0)) * uod.Qty SumPrice ,  
                            CASE WHEN ( uu.UnitID = 1 ) THEN 'ک'  
                                 ELSE 'ب'  
                            END AS Unit ,  
                            uu.UnitID ,  
                            CASE WHEN uod.IsBonus = 0 THEN ' '  
                                 ELSE 'ج'  
                            END AS Reward ,  
                            LTRIM(RTRIM(uc.ProductName)) ProductName ,  
                            CONVERT(INT, ISNULL(ROUND(( SaleCore.dbo.GetUnitConversionRate(uod.ProductCode,  
                                                              uod.UnitID,  
                                                              uc.MainUnitID,  
                                                              '2')  
                                                        * upu.NetWeight ), 1),  
                                                0)) NetWeight ,  
                            IsBonus  
                    FROM    dbo.udft_BusinessDocDetail('2') AS uod  
                            INNER JOIN SaleCore.dbo.udft_PriceListDetail('2')  
                            AS upld ON upld.ProductCode = uod.ProductCode  
                                       AND upld.PriceID = uod.PriceID  
                            INNER JOIN SaleCore.dbo.udft_Coding('2') AS uc ON uc.ProductCode = upld.ProductCode  
                            INNER JOIN dbo.udft_BusinessDoc('2') AS uo ON uo.BusinessDocNo = uod.BusinessDocNo  
                            INNER JOIN SaleCore.dbo.udft_Unit('2') AS uu ON uu.UnitID = uod.UnitID  
                            INNER JOIN SaleCore.dbo.udft_ProductUnit('2') AS upu ON upu.ProductCode = uc.ProductCode  
                                                              AND upu.UnitID = uc.MainUnitID  
                    WHERE   uod.BusinessDocNo = @BusinessDocNo  
                    ORDER BY Row;  
  
  
    
  
    
            SET @Details = ( SELECT Row ,  
                                    QTY ,  
                                    Price ,  
                                    SumPrice ,  
                                    Unit ,  
                                    Reward ,  
                                    ProductName  
                             FROM   @ProductTemp  
                             ORDER BY Row  
                           FOR  
                             JSON AUTO  
                           );  
  
  
            DECLARE @AddDiffTemp TABLE  
                (  
                  Row INT ,  
                  DiscountName NVARCHAR(50) ,  
                  SumPrice NUMERIC(15, 0) ,  
                  IsAddition BIT ,  
                  AddDiffID TINYINT  
                );  
          
            INSERT  INTO @AddDiffTemp  
                    ( Row ,  
                      DiscountName ,  
                      SumPrice ,  
                      IsAddition ,  
                      AddDiffID  
                    )  
                    SELECT  ROW_NUMBER() OVER ( ORDER BY ad.AddDiffID ) AS Row ,  
                            LTRIM(RTRIM(ad.AddDiffName)) DiscountName ,  
                            CAST(ISNULL(bdad.Amount, 0) AS DECIMAL(15, 0)) AS SumPrice ,  
                            ad.IsAddition ,  
                            bdad.AddDiffID  
                    FROM    dbo.udft_BusinessDocAddDiff('2') bdad  
                            INNER JOIN SaleCore.dbo.AddDiff AS ad ON ad.AddDiffID = bdad.AddDiffID  
                    WHERE   BusinessDocNo = @BusinessDocNo;  
   
  
                                                                
            SET @Discount = ( SELECT    adt.Row ,  
                                        adt.DiscountName ,  
                                        adt.SumPrice  
                              FROM      @AddDiffTemp AS adt  
                              WHERE     adt.IsAddition = 0  
                            FOR  
                              JSON AUTO  
                            );  
          
  
            SET @Additions = ( SELECT   adt.Row ,  
                                        adt.DiscountName ,  
                                        adt.SumPrice  
                               FROM     @AddDiffTemp AS adt  
                               WHERE    adt.IsAddition = 1  
                             FOR  
                               JSON AUTO  
                             );  
    
  
            SELECT  @TotalPrice = CAST(ISNULL(SUM(pt.SumPrice), 0) AS NUMERIC(15,  
                                                              0)) ,  
                    @Weight = CONVERT(NVARCHAR(20), CAST(ISNULL(SUM(pt.NetWeight  
                                                              * QTY), 0)/1000 AS DECIMAL(15,  
                                                              2))) ,  
                    @CartonCount = CONVERT(NVARCHAR(50), ISNULL(CAST(SUM(CASE  
                                                              WHEN ( pt.UnitId = 1 )  
                                                              THEN QTY  
                                                              END) AS DECIMAL(15,  
                                                              0)), 0)) ,  
                    @PacketCount = CONVERT(NVARCHAR(20), ISNULL(CAST(SUM(CASE  
                                                              WHEN ( pt.UnitId = 2 )  
                                                              THEN QTY  
                                                              END) AS DECIMAL(15,  
                                                              0)), 0))  
            FROM    @ProductTemp AS pt;    
    
    
            SELECT  @TotalDiscount = CAST(ISNULL(SUM(SumPrice), 0) AS DECIMAL(15,  
                                                              0))  
            FROM    @AddDiffTemp AS at  
            WHERE   at.IsAddition = 0;   
  
    
            SELECT  @TotalAdditions = CAST(ISNULL(SUM(SumPrice), 0) AS DECIMAL(15,  
                                                              0))  
            FROM    @AddDiffTemp AS at  
            WHERE   at.IsAddition = 1;  
   
    
            SELECT  @DiscountPecuniaryPercent = [Percent] * .01  
            FROM    dbo.udft_CustomerAddDiff('2')  
            WHERE   PersonID = @PersonID  
                    AND AddDiffID = 13;  
    
            SELECT  @DiscountPecuniary = ISNULL(ROUND(( @TotalPrice  
                                                        - CAST(ISNULL(SUM(SumPrice),  
                                                              0) AS DECIMAL(15,  
                                                              0)) )  
                                                      * @DiscountPecuniaryPercent,  
                                                      -2), 0)  
            FROM    @AddDiffTemp AS adt  
            WHERE   adt.IsAddition = 30;   
            
  
    
            SELECT  @AfterDiscountPecuniary = @TotalPrice - @DiscountPecuniary  
                    + ISNULL(@TotalAdditions, 0) - ISNULL(@TotalDiscount, 0);  
   
            SELECT  @Payable = @TotalPrice + ISNULL(@TotalAdditions, 0)  
                    - ISNULL(@TotalDiscount, 0);  
            SET @PayableDiscription = 'مبلغ قابل پرداخت ';  
  -- اعتباری   
    
  
      
    
            IF ( @PaymentType = 2 )  
                BEGIN  
                    SET @PayableLetters = dbo.[fn_GetLiteral](@Payable)  
                        + ' ریال ';   
   
SET @Discount = ISNULL(( SELECT Row ,  
                                                    DiscountName ,  
                                                    SaleCore.[dbo].[fn_GetMoneyFormatted](SumPrice,  
                                                              1) SumPrice  
                                             FROM   @AddDiffTemp  
                                             WHERE  SumPrice <> 0  
                                                    AND IsAddition = 0  
                                           FOR  
                                             JSON AUTO  
                                           ), '');    
                END;  
            ELSE  
                IF ( @PaymentType = 1 )  
                    BEGIN  
                        SET @PayableLetters = dbo.[fn_GetLiteral](@AfterDiscountPecuniary)  
                            + ' ریال ';   
                        SET @Payable = @AfterDiscountPecuniary;  
        
                        SET @Discount = ( SELECT    ROW_NUMBER() OVER ( ORDER BY SumPrice ) AS Row ,  
                                                    DiscountName ,  
                                                    SumPrice  
                                          FROM      ( SELECT  DiscountName ,  
                                                              SaleCore.[dbo].[fn_GetMoneyFormatted](SumPrice,  
                                                              1) SumPrice  
                                                      FROM    @AddDiffTemp  
                                                      WHERE   SumPrice <> 0  
                                                              AND IsAddition = 0  
                                                      UNION  
                                                      SELECT  LTRIM(RTRIM('5 درصد تخفیف نقدی')) DiscountName ,  
                                                              SaleCore.[dbo].[fn_GetMoneyFormatted](CAST(@DiscountPecuniary AS DECIMAL(15,  
                                                              0)), 1) AS SumPrice  
                                                    ) t  
                                        FOR  
                                          JSON AUTO  
                                        );    
    
  
                    END;  
  
  
   
                                          
  
   
  
            SET @Retrun = ( SELECT  *  
                            FROM    ( SELECT    @BranchName BranchName ,  
                                                dbo.fn_GetSerialNo(@BusinessDocNo) Id ,  
                                                @CustomerId CustomerId ,  
                                                @CusmtomerName AS CustomerName ,  
                                                @CusmtomerMobile CustomerMobile ,  
                                                @VisitorName AS VisitorName ,  
                                                @VisitorMobile AS VisitorMobile ,  
                                                SaleCore.dbo.[fn_GetMoneyFormatted](@TotalPrice,  
                                                              1) AS TotalPrice ,  
                                                @Weight AS Weight ,  
                                                @CartonCount CartonCount ,  
                                                @PacketCount PacketCount ,  
                                                SaleCore.dbo.[fn_GetMoneyFormatted](@TotalDiscount,  
                                                              1) TotalDiscount ,  
                                                SaleCore.dbo.[fn_GetMoneyFormatted](@TotalAdditions,  
                                                              1) TotalAdditions ,  
                                                @PayableDiscription AS PayableDiscription ,  
                                                SaleCore.dbo.[fn_GetMoneyFormatted](@Payable,  
                                                              1) AS Payable ,  
                                                @PayableLetters AS PayableLetters ,  
                                                @Date date ,  
                                                '[@Details]' AS Detail ,  
                                                '[@Discount]' AS Discount ,  
                                                '[@Additions]' AS Additions  
                                    ) a  
                          FOR  
                            JSON AUTO  
                          );   
       
            SET @Retrun = REPLACE(@Retrun, '"[@Details]"',  
                                  @Details  );  
            SET @Retrun = REPLACE(@Retrun, '"[@Discount]"',  
                                  ISNULL(@Discount, '[]') );  
            SET @Retrun = REPLACE(@Retrun, '"[@Additions]"',  
                                  ISNULL(@Additions, '[]') );  
            DECLARE @NewLineChar AS CHAR(2) = CHAR(13) + CHAR(10);  
              
              SET @Body = N' ضمن تشکر از خرید شما . مشتری گرامی '  
                + ISNULL(@CusmtomerName,'')
                + ' فاکتور محصولات خریداری شده به شرح زیر  صادر گردید  :'  
                + @NewLineChar + 'شماره فاکتور : '  
                + CONVERT(NVARCHAR(10),  ISNULL(@FactorId,'') ) + @NewLineChar + 'تعداد : ';  
        
  
       

            IF @CartonCount > 0  
                BEGIN   
                    SET @Body = @Body + CONVERT(NVARCHAR(10), ISNULL(@CartonCount,'') )  
                        + ' کارتن ';  
                END;   
  
            IF @PacketCount > 0  
                BEGIN   
                    SET @Body = @Body + CONVERT(NVARCHAR(10),ISNULL(@PacketCount,'')  )  
                        + ' بسته  ';  
                 
                END;   
   
            SET @Body = @Body + @NewLineChar;   
          
	 
            SET @Body = @Body + 'مبلغ به عدد : '  
                + SaleCore.dbo.[fn_GetMoneyFormatted](@Payable, 1)  
                + @NewLineChar + ' مبلغ به حروف : ' + @PayableLetters;  
            SET @CustomerIds = CONVERT(NVARCHAR(MAX), @CustomerId) + '|';  
  
  
 
            INSERT dbo.SentMessage
                    ( RunDate ,
                      ProcessedReceiveID ,
                      ToTelNo ,
                      InsertDateTime ,
                      SendDateTime ,
                      MsgBody ,
                      DebugMessage ,
                      IsSent ,
                      ModifyDate ,
                      UserID ,
                      IsDeleted ,
                      IsDelivered
                    )
            VALUES  ( dbo.fn_GetPersianDateTime(GETDATE()) , 
                      0 ,  
                      @CusmtomerMobile ,  
                      GETDATE() , 
                      GETDATE() , -- SendDateTime - datetime
                      @Body , -- MsgBody - nvarchar(max)
                      0 , -- DebugMessage - bit
                      0 , -- IsSent - bit
                      GETDATE() , -- ModifyDate - varchar(25)
                      0 , -- UserID - int
                      0 , -- IsDeleted - bit
                      0  -- IsDelivered - bit
                    )
    
      
             SELECT  @Retrun=RIGHT(@Retrun, LEN(@Retrun) - 1);  
             SELECT  @Retrun=LEFT(@Retrun, LEN(@Retrun) - 1);  
   SELECT @Retrun respone  
            COMMIT TRANSACTION T1;  
        END TRY   
   
        BEGIN CATCH  
     
            DECLARE @errMsg NVARCHAR(MAX);  
    
            SELECT  @errMsg = ERROR_MESSAGE();  
    
            RAISERROR (@errMsg, 18, 1);  
        END CATCH;  
      
    END;  
