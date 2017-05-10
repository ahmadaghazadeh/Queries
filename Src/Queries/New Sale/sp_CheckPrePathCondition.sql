 
-- =============================================
-- Author:		Ahmad Aghazadeh
-- Create date: 1396/02/20
-- Description:	CheckPrePathCondition
-- =============================================
ALTER  PROCEDURE [dbo].[sp_CheckPrePathCondition] @IMEI BIGINT = 0
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @IsCheckPrePathConditions AS NVARCHAR(50);
        SELECT  @IsCheckPrePathConditions = [Value]
        FROM    dbo.BranchSettings
        WHERE   [Key] = 'CheckPrePathConditions';
        IF @IsCheckPrePathConditions = '1'
            BEGIN
                DECLARE @RunDate AS BIGINT= dbo.fn_GetLongDate();
                DECLARE @Date AS NVARCHAR(10)= dbo.fn_GetPersianDate(GETDATE());
                DECLARE @VisitScheduleId AS BIGINT;
                DECLARE @FinancialYear AS BIGINT;
                SELECT  @FinancialYear = FinancialYear
                FROM    dbo.LocalSetting;
                SELECT  @VisitScheduleId = MAX(v.VisitScheduleId)
                FROM    dbo.udft_VisitSchedule(@RunDate) v
                        INNER JOIN dbo.udft_Employee(@RunDate) e ON e.EmployeeID = v.VisitorEmployeeID
                WHERE   e.EmployeeIMEI = @IMEI
                        AND v.FinancialYear = @FinancialYear
                        AND v.PersianDate < @Date;
                IF @VisitScheduleId IS NULL
                    BEGIN
                        SELECT  1;
                    END;
                ELSE
                    BEGIN
                        IF EXISTS ( SELECT  *
                                    FROM    ( SELECT    CASE WHEN p.NotSaleReasonId IS NULL
                                                             THEN o.OrderNo
                                                             ELSE p.NotSaleReasonId
                                                        END AS NotSaleReason
                                              FROM      dbo.udft_PrePath(@RunDate) p
                                                        INNER JOIN dbo.udft_Order(@RunDate) o ON o.PersonID = p.PersonId
                                                        LEFT JOIN dbo.udft_VisitSchedule(@RunDate) v ON v.PersianDate = o.RegDate
                                                              AND v.VisitScheduleId = p.VisitScheduleId
                                              WHERE     p.VisitScheduleId = @VisitScheduleId
                                            ) a
                                    WHERE   a.NotSaleReason IS NULL )
                            BEGIN
                                RAISERROR (N'لطفا علت عدم ویزیت را در پیش مسیر فعلی برای مشتریان مشخص کنید.', 18, 1);
                            END;
                        ELSE
                            BEGIN
                                SELECT  0;
                            END;
                    END;
            END;
    END;
