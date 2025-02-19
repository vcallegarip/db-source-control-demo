SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[a_Interject_CustomerList_Private_Pull]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[a_Interject_CustomerList_Private_Pull] AS' 
END
GO
-- =============================================
-- Author:		Victor Callegari
-- Create date: 12-22-2014
-- Description:	Pull Customer details
-- =============================================

ALTER PROCEDURE [dbo].[a_Interject_CustomerList_Private_Pull]
	 @CustGrouping				VARCHAR(500)	= ''
	,@PortalID					INT				= ''
	,@TestMode					BIT				= 0
	
	
AS

	/*
	
		exec [dbo].[a_Interject_CustomerList_Private_Pull]
			 @CustGrouping	= 'amer'	
			,@PortalID		= 9	
			,@TestMode		= 0	
		
	*/

	SET NOCOUNT ON;
	
	
	-- get main role ids for the portals since each portal has different role ids 
	declare @Portal_RoleIDCustomer	int
	set @Portal_RoleIDCustomer	= 0


	select 
		@Portal_RoleIDCustomer = RoleID		
	from dbo.Roles with(nolock)
	where 
		PortalID = @PortalID
		and RoleName = 'Customer'
		
		
	select * into #GroupingsFromParameter
	from (
			SELECT distinct LTRIM(RTRIM(Element)) as  Element
			FROM [dbo].[cfn_SplitList](@CustGrouping,',')
		 ) t
	

	SELECT Distinct
		 ud.UserID
	FROM [dbo].[ctbl_UserData] ud with(nolock)
		LEFT JOIN [dbo].[Users] u with(nolock)
			ON u.UserID = ud.UserID
		LEFT join [dbo].[Interject_CustomerGroups] ic with(nolock)
			on ic.CustomerID = ud.UserID
		INNER JOIN (
				select up.UserID,up.PortalID,ur.RoleID
				from [dbo].[UserPortals] up with(nolock)
					full outer join [dbo].UserRoles ur with(nolock)
						on ur.UserID = up.UserID
				where PortalID = @PortalID
				and ur.RoleID = @Portal_RoleIDCustomer
				  ) t
			on t.UserID = u.UserID
		INNER JOIN #GroupingsFromParameter g
			on ic.GroupingCode like '%' + g.Element + '%'
GO
