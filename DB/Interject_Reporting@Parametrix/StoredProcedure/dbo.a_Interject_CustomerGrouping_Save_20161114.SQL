SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[a_Interject_CustomerGrouping_Save_20161114]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[a_Interject_CustomerGrouping_Save_20161114] AS' 
END
GO

-- =============================================
-- Author:		Victor Callegari
-- Create date: 12-22-2014
-- Description:	Save Customer Groupings
-- =============================================

ALTER PROCEDURE [dbo].[a_Interject_CustomerGrouping_Save_20161114]
	  @Interject_XMLDataToSave	TEXT
	 ,@RequesterUserName 		VARCHAR(50)		= ''
	 ,@PortalPublicID			VARCHAR(100)	= ''	
	 ,@Interject_ReturnError	VARCHAR(2000)	= '' OUTPUT  
	 ,@TestMode					BIT = 0
	
AS

	/*
		
		// securtity
		make sure the userid belong to the @PortalPublicID

		DECLARE @Interject_ReturnError VARCHAR(500)

		DECLARE @Interject_XMLDataToSave VARCHAR(8000)
		SET @Interject_XMLDataToSave = 
			'
			 <Root>
				  <r>
					<Row>18</Row>
					<UserID>33827</UserID>
					<GroupingCode></GroupingCode>
				  </r>
				  <r>
					<Row>19</Row>
					<UserID>45401</UserID>
					<GroupingCode></GroupingCode>
				  </r>
				  <r>
					<Row>20</Row>
					<UserID>46647</UserID>
					<GroupingCode></GroupingCode>
				  </r>
				  <r>
					<Row>21</Row>
					<UserID>63124</UserID>
					<GroupingCode>BBB</GroupingCode>
				  </r>
			</Root>
			'
		Exec a_Interject_CustomerGrouping_Save
			  @Interject_XMLDataToSave	= @Interject_XMLDataToSave
			 ,@PortalPublicID			= 'FAE46024-4C0B-4A29-8399-02AFCB595085'
			 ,@RequesterUserName		= 'JoeOwner'
			 ,@Interject_ReturnError	= @Interject_ReturnError out
			 ,@TestMode					= 0
			
		select @Interject_ReturnError
		
	*/

	SET NOCOUNT ON
	

	-- Security. Validate the @PortalPublicID and @RequesterUserName
	
	DECLARE	@WasDenied			BIT
	DECLARE @RequesterUserID	INT 
	DECLARE @PortalID			INT 
	DECLARE @Message			VARCHAR(1000)
	
	set @WasDenied = 1

	exec [dbo].[a_Interject_ValidateCall]
		 @PortalPublicID		= @PortalPublicID
		,@RequesterUserName		= @RequesterUserName
		,@QueryName				= '[dbo].[a_Interject_CustomerGrouping_Save]'
		,@WasDenied				= @WasDenied		output
		,@RequesterUserID		= @RequesterUserID	output
		,@PortalID				= @PortalID			output
		,@Message				= @Message			output
		,@ParamValues			= ''

	if @TestMode = 1
		select		
			 @WasDenied			as 'WasDenied'
			,@RequesterUserID	as 'RequesterUserID'
			,@PortalID			as 'PortalID'
			,@Message			as 'Message'



	IF ISNULL(@Message,'') <> ''
	begin
		set @Interject_ReturnError = 'UserNotice:' + @Message
	end
	

	if @WasDenied = 1 or @Message <> ''
		return
		
		
	-- this table holds data from the spreadsheet	
	CREATE TABLE #DataFromSpreadSheet
	(
		 TheID			INT IDENTITY
		,[Row]			INT
		,UserID			INT
		,GroupingCode	VARCHAR(500)
		,SaveResult		VARCHAR(500) default('')
	)
	
	
	DECLARE @hDoc AS INT
	
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @Interject_XMLDataToSave
	
	
	-- inserted data from the xml (spreadsheet)
	INSERT INTO #DataFromSpreadSheet
	(
		 [Row]
		,UserID
		,GroupingCode
		,SaveResult
	)
	SELECT
		 [Row] 
		,UserID
		,GroupingCode
		,''
	FROM OPENXML(@hDoc, '/Root/r',2)
	WITH 
	(	
		 [Row]			INT
		,UserID			INT
		,GroupingCode	VARCHAR(50)
	)
	
	EXEC sp_xml_removedocument @hDoc
	
	
	if @TestMode = 1
	begin
		select '#DataFromSpreadSheet'
		select * From #DataFromSpreadSheet
	end
	

	-- split Customer Groupings to validate user input
	-- CROSS APPLY DOES NOT WORK ON SQL SERVER 2000
	
	--select * into #Splited_CustGroups_Excel
	--from (
	--SELECT
	--	 d.Row
	--	,d.UserID
	--	,RTRIM(LTRIM(ca.[Element])) AS Element
	--FROM #DataFromSpreadSheet  d
	--CROSS APPLY [dbo].[cfn_SplitList](d.GroupingCode,',') AS ca
	--	) t
	
	
	
	-- split Customer Groupings to validate user input
	-- TODO: Check if this approach is efficient
	--
	select * into #Splited_CustGroups_Excel
	from (
		SELECT
			 t.Row
			,t.UserID
			,t.Value AS Element
		FROM (	
				SELECT a.Row,a.UserID,a.GroupingCode, 
					   SUBSTRING(',' + a.GroupingCode + ',', n.Number + 1, CHARINDEX(',', ',' + a.GroupingCode + ',', n.Number + 1) - n.Number - 1) AS Value
				FROM #DataFromSpreadSheet AS a
					INNER JOIN master..spt_values AS n ON SUBSTRING(',' + a.GroupingCode + ',', n.Number, 1) = ','
				WHERE n.Type = 'p'
				  AND n.Number > 0 
				  AND n.Number < LEN(',' + a.GroupingCode + ',')					
			 ) t
		 ) t
		
		
		
	if @TestMode = 1
	begin
		select '#Splited_CustGroups_Excel'
		select * From #Splited_CustGroups_Excel
	end	
	
	
	
	-- validate if user is passing two equal roles
	UPDATE dts
		SET dts.SaveResult = dts.SaveResult + 'The Entered Grouping Code already exist.'
	FROM #DataFromSpreadSheet dts
		INNER JOIN (
			select
				s.UserID
				,s.Element
			from #Splited_CustGroups_Excel s
			group by 
				s.UserID
				,s.Element
			HAVING COUNT(*) > 1
					) t
			on t.UserID = dts.UserID
	

	--
	-- check if UserID from the xml belong to the correct Role
	--
	
	-- get main role ids for the portals since each portal has different role ids 
	declare @Portal_RoleIDCustomer int
	set @Portal_RoleIDCustomer = 0


	select 
		@Portal_RoleIDCustomer = RoleID		
	from dbo.Roles with(nolock)
	where 
		PortalID = @PortalID
		and RoleName = 'Customer'
		
	

	-- validate if user does not belong the the current role.
	UPDATE dts
		SET dts.SaveResult = dts.SaveResult +  'This user does not belong to the current Customer Role.'
	FROM #DataFromSpreadSheet dts
		LEFT JOIN (
					select up.UserID
					from [dbo].[UserPortals] up with(nolock)
						inner join [dbo].UserRoles ur with(nolock)
							on ur.UserID = up.UserID
					where up.PortalID = @PortalID
					and ur.RoleID = @Portal_RoleIDCustomer
				  ) t
			on t.UserID = dts.UserID
	where t.UserID is null

	
	
	DECLARE @HasErrors BIT
	set @HasErrors = 0
	
	
	
	-- check for error after validations
	IF EXISTS (select 1 from #DataFromSpreadSheet where isnull(LTRIM(RTRIM(SaveResult)),'') <> '')
	BEGIN
		
		set @HasErrors = 1
		
		set @Interject_ReturnError = 'UserNotice:Errors were found. Unable to complete the save process.'
		GOTO ResultSetFinal
	
	END
	
	
	-- updating temp table in case changes were perform		
	UPDATE d
	SET d.[SaveResult] = 'Updated' 
	FROM #DataFromSpreadSheet d
	where d.UserID in 
			(
				select s.UserID
				from #Splited_CustGroups_Excel s
				left JOIN [dbo].[Interject_CustomerGroups] a
						on a.CustomerID = s.UserID
						and a.GroupingCode  = s.Element
				where a.CustomerID is null
				
				union -- no duplicates
				
				select a.CustomerID
				from #Splited_CustGroups_Excel s
				right JOIN [dbo].[Interject_CustomerGroups] a
						on a.CustomerID = s.UserID
						and a.GroupingCode  = s.Element
				where s.UserID is null
			)
		
	 
	 -- if there were no changes, mark the result as 'No Changes'
	 UPDATE d
		SET d.[SaveResult] = 'No Changes' 
	 FROM #DataFromSpreadSheet d
		left join [dbo].[Interject_CustomerGroups] icg
		on icg.CustomerID = d.Userid
	where icg.CustomerID is null
		and isnull(d.GroupingCode,'') = '' 
		or d.SaveResult = ''
		
		
   				     
					
	IF @TestMode = 1
	begin
		select '#DataFromSpreadSheet After Update'
		select * from #DataFromSpreadSheet
	end
	
	
	-- in case everything is OK. Do the Update.
	-- Try catch was not done since this is not critical process.
	if @TestMode = 0
	begin
		
		delete cg
		from [dbo].[Interject_CustomerGroups] cg
			left join #Splited_CustGroups_Excel s
				on  s.UserID  = cg.CustomerID
				and s.Element = cg.GroupingCode
			inner join #DataFromSpreadSheet d
				on d.SaveResult = 'Updated'
		where cg.CustomerID = d.UserID
			and cg.PortalID = @PortalID

		
		Insert Into [dbo].[Interject_CustomerGroups]
		(
			 CustomerID
			,GroupingCode
			,PortalID
		)		
		select 
			 s.UserID
			,s.Element
			,@PortalID
		from #Splited_CustGroups_Excel s
			left join [dbo].[Interject_CustomerGroups] a
				on a.CustomerID = s.UserID
				and a.GroupingCode = s.Element
			inner join #DataFromSpreadSheet d
				on d.SaveResult = 'Updated'
		where a.GroupingCode is null
		and s.Element <> ''
		group by 
			 s.UserID
			,s.Element
		
		
	end

	
ResultSetFinal:

	select 
		 [Row]
		,SaveResult
	from #DataFromSpreadSheet

GO
