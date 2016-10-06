

BEGIN TRANSACTION;

BEGIN TRY

    -- In
    DECLARE @MaxTkeyIn AS INTEGER;
    DECLARE @MaxIdIn AS INTEGER;
    DECLARE @MaxAccIn AS INTEGER;
    DECLARE @MaxTkeyDIn AS INTEGER;
	DECLARE @SourceStore AS INTEGER= 2;
    DECLARE @DestStore AS INTEGER= 1;
	DECLARE @Date AS NVARCHAR(10)=N'1395/07/14';
	DECLARE @Time AS NVARCHAR(5)=N'14:59';
	DECLARE @User AS NVARCHAR(50)= N'aghzadeh-a';

    SELECT  @MaxTkeyIn = MAX(h.tkey)+1
    FROM    dbo.inputs_h h;
    SELECT  @MaxIdIn = MAX(h.id)+1
    FROM    dbo.inputs_h h
    WHERE   h.basekind = 6;
    SELECT  @MaxAccIn = MAX(a.accid)+1
    FROM    dbo.accids a;
    SELECT  @MaxTkeyDIn = MAX(od.tkey)
    FROM    dbo.inputs_d od;


	INSERT INTO dbo.accids
	        ( accid ,
	          mashinname ,
	          accdate ,
	          acctime ,
	          isclosed
	        )
	VALUES  ( @MaxAccIn , -- accid - int
	          @User , -- mashinname - nvarchar(max)
	          @Date , -- accdate - char(10)
	          @Time , -- acctime - char(5)
	          NULL  -- isclosed - bit
	        )

 
    INSERT  INTO dbo.inputs_h
            ( tkey ,
              id ,
              date ,
              factornumber ,
              basekind ,
              stkey ,
              pstkey ,
              reqkey ,
              accid ,
              moshkey ,
              back_type ,
              pnumber
            )
    VALUES  ( @MaxTkeyIn , -- tkey - int
              @MaxIdIn , -- id - int
              @Date , -- date - char(10)
              NULL , -- factornumber - int
              6 , -- basekind - int
              @DestStore , -- stkey - int
              @SourceStore , -- pstkey - int
              NULL , -- reqkey - int
              @MaxAccIn , -- accid - int
              NULL , -- moshkey - int
              0 , -- back_type - bit
              NULL  -- pnumber - int
            );

    INSERT  INTO dbo.inputs_d
            ( tkey ,
              htkey ,
              radif ,
              cdkey ,
              shenase ,
              qty ,
              price ,
              factorkey ,
              ofyear ,
              backkind
            )
            SELECT  ( ROW_NUMBER() OVER ( ORDER BY cdkey ) ) + @MaxTkeyDIn ,
                    @MaxTkeyIn ,
                    ( ROW_NUMBER() OVER ( ORDER BY cdkey ) ) ,
                    cdkey ,
                    shenase ,
                    mojody ,
                    price ,
                    null,
                    NULL ,
                    NULL 
            FROM    dbo.mojody
            WHERE   store_id = @SourceStore
                    AND mojody > 0;

--Output
    DECLARE @MaxTkeyOut AS INTEGER;
    DECLARE @MaxIdOut AS INTEGER;
    DECLARE @MaxAccOut AS INTEGER;
    DECLARE @MaxTkeyDOut AS INTEGER;


    SELECT  @MaxTkeyOut = MAX(h.tkey)+1
    FROM    dbo.outputs_h h;
    SELECT  @MaxIdOut = MAX(h.id)+1
    FROM    dbo.outputs_h h
    WHERE   h.basekind = 6;
    SELECT  @MaxAccOut = MAX(a.accid)+1
    FROM    dbo.accids a;
    SELECT  @MaxTkeyDOut = MAX(od.tkey)
    FROM    dbo.outputs_d od;

	 
	INSERT INTO dbo.accids
	        ( accid ,
	          mashinname ,
	          accdate ,
	          acctime ,
	          isclosed
	        )
	VALUES  ( @MaxAccOut , -- accid - int
	          @User , -- mashinname - nvarchar(max)
	          @Date , -- accdate - char(10)
	          @Time , -- acctime - char(5)
	          NULL  -- isclosed - bit
	        )
    INSERT  INTO dbo.outputs_h
            ( tkey ,
              id ,
              date ,
              stkey ,
              bardate ,
              pstkey ,
              moshkey ,
              orderid ,
              tdrm ,
              cocode ,
              npa ,
              basekind ,
              accid ,
              pnumber ,
              fdesc ,
              rasmi ,
              MANUAL ,
              comment
            )
    VALUES  ( @MaxTkeyOut , -- tkey - int
              @MaxIdOut , -- id - int
              @Date , -- date - char(10)
              @SourceStore , -- stkey - int قزوین
              '' , -- bardate - char(10)
              @DestStore , -- pstkey - int کرج
              NULL , -- moshkey - int
              NULL , -- orderid - int
              NULL , -- tdrm - int
              NULL , -- cocode - int
              NULL , -- npa - int
              6 , -- basekind - int
              @MaxAccOut , -- accid - int
              NULL , -- pnumber - int
              NULL , -- fdesc - nvarchar(60)
              NULL , -- rasmi - int
              NULL , -- MANUAL - bit
              ''  -- comment - varchar(100)
            );

    INSERT  INTO dbo.outputs_d
            ( tkey ,
              htkey ,
              radif ,
              cdkey ,
              qty ,
              price ,
              shenase ,
              rowkind ,
              backkind
		    )
            SELECT  ( ROW_NUMBER() OVER ( ORDER BY cdkey ) ) + @MaxTkeyDOut ,
                    @MaxTkeyOut ,
                    ( ROW_NUMBER() OVER ( ORDER BY cdkey ) ) ,
                    cdkey ,
                    mojody ,
                    price ,
                    shenase ,
                    0 ,
                    NULL
            FROM    dbo.mojody
            WHERE   store_id = @SourceStore
                    AND mojody > 0;

					-- INput
  


END TRY
BEGIN CATCH
    SELECT  ERROR_NUMBER() AS ErrorNumber ,
            ERROR_SEVERITY() AS ErrorSeverity ,
            ERROR_STATE() AS ErrorState ,
            ERROR_PROCEDURE() AS ErrorProcedure ,
            ERROR_LINE() AS ErrorLine ,
            ERROR_MESSAGE() AS ErrorMessage;

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
GO