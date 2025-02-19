SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[a_Interject_BookingStatus_Pull]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[a_Interject_BookingStatus_Pull] AS' 
END
GO
ALTER procedure [dbo].[a_Interject_BookingStatus_Pull]
	@Interject_ErrorMessage varchar(2000) output
	,@PortalPublicID varchar(100)
	,@RequesterUserName varchar(100)	
	,@AgentProfileID int = 0
	,@RequestStatusCode varchar(100) = ''
	,@txtAgentName_First varchar(50) = ''
	,@txtAgentName_Last varchar(50) = ''
	,@txtBorrowerLastName varchar(50) = ''
	,@CustomerProfileID int = 0
	,@CustomerName varchar(200) = ''
	,@Date_From datetime output
	,@Date_To datetime output
	,@RequestSeqID int = 0
	,@CustomerGroup varchar(2000)
	,@W9onFile	varchar(10) = '' --no used
	,@AgentPaymentTotal	varchar(10) = ''--no used
	,@TestMode bit = 0

as
set nocount on

/*
--sp_updatestats

declare 
	@Interject_ErrorMessage varchar(2000)
	,@Date_From datetime
	,@Date_To datetime
set @Date_From = '12/01/2016'
set @Date_To = '' -- '12/31/2016'
exec [dbo].[a_Interject_BookingStatus_Pull]
		@Interject_ErrorMessage = @Interject_ErrorMessage output
		,@PortalPublicID = 'FAE46024-4C0B-4A29-8399-02AFCB5950D9'
		,@RequesterUserName = 'JoeOwner'	
		,@AgentProfileID = 0
		,@RequestStatusCode = ''
		,@txtAgentName_First = ''
		,@txtAgentName_Last = ''
		,@txtBorrowerLastName = ''
		,@CustomerProfileID = 0
		,@CustomerName = ''
		,@Date_From = @Date_From output
		,@Date_To =  @Date_To output
		,@RequestSeqID = 0
		,@CustomerGroup = ''
		,@W9onFile	= ''
		,@AgentPaymentTotal	= ''
		,@TestMode = 0
	select 
		@Interject_ErrorMessage as '@Interject_ErrorMessage'
		,@Date_From as 'Date_From'
		,@Date_To as 'Date_To'

*/

Declare @Status varchar(10)
Declare @StatusCodeIDBegin int 
Declare @StatusCodeIDEnd int 

--
--	security routine for Interject 
--

	declare @ParamValues varchar(2000)
	set @ParamValues = 
		'@AgentProfileID=' + isnull(cast(@AgentProfileID as varchar(20)),'[Null]')
		+',@RequestStatusCode=' + isnull(@RequestStatusCode,'[Null]')
		+',@txtAgentName_First=' + isnull(@txtAgentName_First,'[Null]')
		+',@txtAgentName_Last=' + isnull(@txtAgentName_Last,'[Null]')
		+',@txtBorrowerLastName=' + isnull(@txtBorrowerLastName,'[Null]')
		+',@CustomerProfileID=' + isnull(cast(@CustomerProfileID as varchar(20)),'[Null]')
		+',@CustomerName=' + isnull(@CustomerName,'[Null]')
		+',@Date_From=' + isnull(convert(varchar(20),@Date_From,101),'[Null]')
		+',@Date_To=' + isnull(convert(varchar(20),@Date_To,101),'[Null]')
		+',@RequestSeqID=' + isnull(cast(@RequestSeqID as varchar(20)),'[Null]')
		+',@CustomerGroup=' + isnull(cast(@CustomerGroup as varchar(500)),'[Null]')

	declare 
		@WasDenied bit
		,@RequesterUserID int 
		,@PortalID int 
		,@Message varchar(1000)
	
	set @WasDenied = 1
	
	exec [dbo].[a_Interject_ValidateCall]
		@PortalPublicID = @PortalPublicID
		,@RequesterUserName = @RequesterUserName
		,@QueryName = '[a_Interject_BookingStatus_Pull]'
		--,@QueryName = '[a_Interject_Report_002_RequestDetails]'
		,@WasDenied = @WasDenied output
		,@RequesterUserID = @RequesterUserID output
		,@PortalID = @PortalID output
		,@Message = @Message output
		,@ParamValues = @ParamValues

	if @TestMode = 1
		select		
			@WasDenied as 'WasDenied'
			,@RequesterUserID as 'RequesterUserID'
			,@PortalID as 'PortalID'
			,@Message as 'Message'

	set @Interject_ErrorMessage = @Message

	if @WasDenied = 1 or @Message <> ''
		return

--
-- end of security
--


--
--	start of parameter mapping
--

	-- get main role ids for the portals since each portal has different role ids 
	declare @Portal_RoleIDAgent int
	declare @Portal_RoleIDCustomer int
	set @Portal_RoleIDAgent = 0
	set @Portal_RoleIDCustomer = 0

	select 
		@Portal_RoleIDAgent = RoleID		
	from dbo.Roles
	where 
		PortalID = @PortalID
		and RoleName = 'NotaryAgent'

	select 
		@Portal_RoleIDCustomer = RoleID		
	from dbo.Roles
	where 
		PortalID = @PortalID
		and RoleName = 'Customer'

	if @TestMode = 1
		select 
			@Portal_RoleIDAgent as '@Portal_RoleIDAgent'
			,@Portal_RoleIDCustomer as '@Portal_RoleIDCustomer'

	-- map the status text to internal requirements
	set @StatusCodeIDBegin = 0 
	set @StatusCodeIDEnd = 99
	if @RequestStatusCode = 'Open: New' 
		Begin
			set @StatusCodeIDBegin = 1
			set @StatusCodeIDEnd = 1		
		end
	if @RequestStatusCode = 'Open: Pending' 
		Begin
			set @StatusCodeIDBegin = 2
			set @StatusCodeIDEnd = 2
		end
	if @RequestStatusCode = 'Open: Appt Confirmed' 
		Begin
			set @StatusCodeIDBegin = 3
			set @StatusCodeIDEnd = 3
		end
	if @RequestStatusCode = 'Billing: Appt Complete. To Invoice' 
		Begin
			set @StatusCodeIDBegin = 4
			set @StatusCodeIDEnd = 4
		end
	if @RequestStatusCode = 'Billing: Invoiced. Awaiting Pmt' 
		Begin
			set @StatusCodeIDBegin = 5
			set @StatusCodeIDEnd = 5
		end
	if @RequestStatusCode = 'Closed: Paid' 
		Begin
			set @StatusCodeIDBegin = 6
			set @StatusCodeIDEnd = 6
		end
	if @RequestStatusCode = '-All "Open"-' 
		Begin
			set @StatusCodeIDBegin = 1
			set @StatusCodeIDEnd = 3		
		end
	if @RequestStatusCode = '-All "Billing"-' 
		Begin
			set @StatusCodeIDBegin = 4
			set @StatusCodeIDEnd = 5	
		end
	if @RequestStatusCode = '-All Items(Excluding Dec/Canc)-'
		Begin
			set @StatusCodeIDBegin = 1
			set @StatusCodeIDEnd = 6				
		end
	if @RequestStatusCode = '-All Items(Including Dec/Canc)-' 
		Begin
			set @StatusCodeIDBegin = 1
			set @StatusCodeIDEnd = 10				
		end	
	if @RequestStatusCode = 'Declined' 
		Begin
			set @StatusCodeIDBegin = 9
			set @StatusCodeIDEnd = 9				
		end		
	if @RequestStatusCode = 'Canceled' 
		Begin
			set @StatusCodeIDBegin = 10
			set @StatusCodeIDEnd = 10				
		end				

	-- customer like search (normally limited number for each portal)
	create table #CustomerIDs
	(CustomerID int)
	
	declare @UseCustomerSearch bit 
	set @UseCustomerSearch = 0

	if @CustomerProfileID <> 0
	begin
		set @UseCustomerSearch = 1

		insert into #CustomerIDs
		(CustomerID)		
		select @CustomerProfileID
	end

	if @CustomerName <> ''
	begin
		set @UseCustomerSearch = 1

		insert into #CustomerIDs
		(CustomerID)
		select
			u.UserID
		from dbo.ctbl_UserData u with(nolock)
			inner join dbo.UserRoles ur with(nolock)
				on
				u.UserID = ur.UserID
				and 
				ur.RoleID = @Portal_RoleIDCustomer
			inner join dbo.UserPortals up with(nolock)
				on up.UserID = u.UserID
					and up.PortalID = @PortalID
		where 
			u.CompanyName like '%' + @CustomerName + '%'
	end
	
	
	if @CustomerGroup <> ''
	begin
	
		set @UseCustomerSearch = 1
				
		Insert Into #CustomerIDs
		exec [dbo].[a_Interject_CustomerList_Private_Pull]
			 @CustGrouping	= @CustomerGroup	
			,@PortalID		= @PortalID	
			,@TestMode		= 0	

	end
	
	

	-- handle nulls
	set @Date_From = isnull(nullif(@Date_From,'1/1/1900'),'1/1/1900')
	set @Date_To = isnull(nullif(@Date_To,'1/1/1900'),'1/1/2050')
	set @txtAgentName_First= isnull(@txtAgentName_First,'')
	set @txtAgentName_Last= isnull(@txtAgentName_Last,'')

	-- assume dates when not input
	if @Date_From = '1/1/1900' and @Date_To <> '1/1/2050'
	begin
		set @Date_From = '1/1/' + cast(year(@Date_To) as varchar(4))
	end
	else if @Date_From <> '1/1/1900' and @Date_To = '1/1/2050'
	begin
		set @Date_To = '12/31/' + cast(year(@Date_From) as varchar(4))
	end
	else if @Date_From = '1/1/1900' and @Date_To = '1/1/2050'
	begin
		set @Date_From = '1/1/' + cast(year(getdate()) as varchar(4))
		set @Date_To = '12/31/' + cast(year(getDate()) as varchar(4))
	end

	if @TestMode = 1
		select 
			@UseCustomerSearch as '@UseCustomerSearch'
			,@Date_From as '@Date_From'
			,@Date_To as '@Date_To'
--
-- end of parameter mapping
--


Select top 20000
	SR.RequestSeqID,
	--AddDateTime AS AddDateTime,
	UpdateDateTime AS UpdateDateTime,
	--SigningRequestStatus, 
	SR.RequestDate as CreatedDate,
	isnull(BorrowerFirstName,'') as BorrowerFirstName,  
	isnull(SR.BorrowerLastName,'') as BorrowerLastName, 
	isnull(SR.CoBorrowerFirstName,'') as CoBorrowerFirstName, 
	isnull(SR.CoBorrowerLastName,'') as CoBorrowerLastName, 
	isnull(SR.SigningAddress1,'') as BorrowerAddress1, 
	isnull(SR.SigningAddress2,'') as BorrowerAddress2, 
	isnull(SR.SigningCity,'') as BorrowerCity, 
	isnull(SR.SigningState,'') as BorrowerState, 
	isnull(SR.SigningZip,'') as BorrowerZipCode, 


	isnull(SRB.AltLoc_Name,'') as AltSigningLocation_Name, 
	isnull(SRB.AltLoc_Add1,'') as AltSigningLocation_Address1, 
	isnull(SRB.AltLoc_Add2,'') as AltSigningLocation_Address2, 
	isnull(SRB.AltLoc_City,'') as AltSigningLocation_City, 
	isnull(SRB.AltLoc_State,'') as AltSigningLocation_State, 
	isnull(SRB.AltLoc_Zip,'') as AltSigningLocation_Zip, 


	isnull(SR.SigningDaytimePhone,'') as BorrowerDayPhone, 
	isnull(SR.SigningEveningPhone,'') as BorrowerEveningPhone, 
	isnull(SR.SigningOtherPhone,'') as BorrowerOtherPhone, 
	isnull(SR.SigningOtherContactInfo,'') as BorrowerOtherContactInfo, 
	isnull(SR.BorrowerEmail1,'') as BorrowerEmailAddress, 
	convert(varchar(20),SR.SigningDate,101) as SigningDate, 
	isnull(SR.SigningTime,'') as SigningTime, 
	isnull(SR.LoanNumber,'') as LoanNumber,
	isnull(SR.LoanNumber2,'') as LoanNumber2,
	isnull(SR.WillSendDocsVia,'') as WillSendDocsVia,
	isnull(SR.LanguagePref,'') as LanguagePref,
	SR.UserID as LoanOfficerCompanyID,
	isnull(SR.LoanOfficerCompany,'') as LoanOfficerCompany, 
	--isnull(CustInfo.CompanyName,'') as CustomerCompany,
	isnull(SR.LoanOfficerName,'') as LoanOfficerName, 
	isnull(SR.LoanOfficerPhone,'') as LoanOfficerPhone, 
	isnull(SR.LoanOfficerEmail,'') as LoanOfficerEmail, 
	isnull(SR.ShipperAccount,'') as ShipperAccount, 
	isnull(ShippingInstructions,'') as ShippingInstructions, 
	isnull(SR.ContactName,'') as ContactName, 
	isnull(SR.ContactPhone,'') as ContactPhone, 
	isnull(SR.ContactCell,'') as ContactCell, 
	isnull(SR.ContactFax,'') as ContactFax, 
	isnull(SR.ContactEmail,'') as ContactEmail, 
	isnull(SR.OtherComments,'') as OtherComments, 
	isnull(SR.OtherConfirmEmail,'') as OtherConfirmEmail,
	isnull(SR.AssignedAgent,0) as AssignedAgentID,
	Case When Users.UserID Is Null then 'No Notary' else isnull(Users.FirstName,'') + ' ' + isnull(Users.LastName,'') end as AssignedAgentName,
	ISNULL(Users.Email , '') as AgentEmail,
	ISNULL(Users.City,'') as AgentCity, -- Stan added 6/8/16
	ISNULL(Users.Region,'') as AgentState, -- Stan added 6/8/16
	ISNULL(Users.PostalCode,'') as AgentZip, -- Stan added 6/8/16
	ISNULL(UD.Telephone2,'') as AgentWorkPhone, --added 4/11/13. Brings in agent work phone from their profile
	ISNULL (ACD.SO_Comments,'') as SO_Comments, -- stan added 10/26/16
	ISNULL (ACD.Reg_Custom1,'') as CustomReg1, -- stan added 10/26/16
	ISNULL (ACD.Reg_Custom2,'') as CustomReg2, -- stan added 10/26/16
	SR.SigningStatusID,
	isnull(SRS.StatusNameShort,'') as SigningStatusDesc,
	isnull(SR.PriceDesc_Cust1,'') as PriceDesc_Cust1, isnull(SR.PriceAmt_Cust1,0) as PriceAmt_Cust1,
	isnull(SR.PriceDesc_Cust2,'') as PriceDesc_Cust2, isnull(SR.PriceAmt_Cust2,0) as PriceAmt_Cust2,
	isnull(SR.PriceDesc_Cust3,'') as PriceDesc_Cust3, isnull(SR.PriceAmt_Cust3,0) as PriceAmt_Cust3,
	isnull(SR.PriceDesc_Cust4,'') as PriceDesc_Cust4, isnull(SR.PriceAmt_Cust4,0) as PriceAmt_Cust4,
	isnull(SR.PriceDesc_Cust5,'') as PriceDesc_Cust5, isnull(SR.PriceAmt_Cust5,0) as PriceAmt_Cust5,
						
	isnull(SR.PriceQty_Cust1,0) as PriceQty_Cust1,
	isnull(SR.PriceQty_Cust2,0) as PriceQty_Cust2,
	isnull(SR.PriceQty_Cust3,0) as PriceQty_Cust3,
	isnull(SR.PriceQty_Cust4,0) as PriceQty_Cust4,
	isnull(SR.PriceQty_Cust5,0) as PriceQty_Cust5,	
	
	case 
		when   isnull(SR.PriceQty_Cust1,0) > 0
			or isnull(SR.PriceQty_Cust2,0) > 0
			or isnull(SR.PriceQty_Cust3,0) > 0
			or isnull(SR.PriceQty_Cust4,0) > 0
			or isnull(SR.PriceQty_Cust5,0) > 0
			
			then	isnull(SR.PriceQty_Cust1,0) * isnull(SR.PriceAmt_Cust1,0)
				+	isnull(SR.PriceQty_Cust2,0) * isnull(SR.PriceAmt_Cust2,0)
				+	isnull(SR.PriceQty_Cust3,0) * isnull(SR.PriceAmt_Cust3,0)
				+	isnull(SR.PriceQty_Cust4,0) * isnull(SR.PriceAmt_Cust4,0)
				+	isnull(SR.PriceQty_Cust5,0) * isnull(SR.PriceAmt_Cust5,0)
			else 0
	end CustAmtTotal,
	
	isnull(SR.PriceDesc_Agent1,'') as PriceDesc_Agent1, isnull(SR.PriceAmt_Agent1,0) as PriceAmt_Agent1,
	isnull(SR.PriceDesc_Agent2,'') as PriceDesc_Agent2, isnull(SR.PriceAmt_Agent2,0) as PriceAmt_Agent2,
	isnull(SR.PriceDesc_Agent3,'') as PriceDesc_Agent3, isnull(SR.PriceAmt_Agent3,0) as PriceAmt_Agent3,
	isnull(SR.PriceDesc_Agent4,'') as PriceDesc_Agent4, isnull(SR.PriceAmt_Agent4,0) as PriceAmt_Agent4,
	isnull(SR.PriceDesc_Agent5,'') as PriceDesc_Agent5, isnull(SR.PriceAmt_Agent5,0) as PriceAmt_Agent5,
	
	isnull(SR.PriceQty_Agent1,0) as PriceQty_Agent1, 
	isnull(SR.PriceQty_Agent2,0) as PriceQty_Agent2, 
	isnull(SR.PriceQty_Agent3,0) as PriceQty_Agent3, 
	isnull(SR.PriceQty_Agent4,0) as PriceQty_Agent4,
	isnull(SR.PriceQty_Agent5,0) as PriceQty_Agent5,	
	
	
	case 
		when   isnull(SR.PriceQty_Agent1,0) > 0
			or isnull(SR.PriceQty_Agent2,0) > 0
			or isnull(SR.PriceQty_Agent3,0) > 0
			or isnull(SR.PriceQty_Agent4,0) > 0
			or isnull(SR.PriceQty_Agent5,0) > 0
			
			then	isnull(SR.PriceQty_Agent1,0) * isnull(SR.PriceAmt_Agent1,0)
				+	isnull(SR.PriceQty_Agent2,0) * isnull(SR.PriceAmt_Agent2,0)
				+	isnull(SR.PriceQty_Agent3,0) * isnull(SR.PriceAmt_Agent3,0)
				+	isnull(SR.PriceQty_Agent4,0) * isnull(SR.PriceAmt_Agent4,0)
				+	isnull(SR.PriceQty_Agent5,0) * isnull(SR.PriceAmt_Agent5,0)
			else 0
	end AgentAmtTotal,

		
	--Isnull(SR.CompletionDate,0) as CompletionDate,
	Isnull(convert(varchar(20),SR.CompletionDate,101),'') as CompletionDate,
	isnull(SR.CompletionTime,'') as CompletionTime,
	--isnull(SR.CompletionReturnedDate,0) as CompletionReturnedDate,
	Isnull(convert(varchar(20),SR.CompletionReturnedDate,101),'') as CompletionReturnedDate,
	isnull(SR.CompletionReturnedVia,'') as CompletionReturnedVia,
	isnull(SR.CompletionTrackingNumber,'') as CompletionTrackingNumber,
	isnull(SR.CompletionComments,'') as CompletionComments,
	
	isnull(SR.HudIn,0) as TitleIn, 
	isnull(SR.DocsIn,0) as LoanDocsIn, 
	cast(isnull(SR.DocsIn,0) as char(1)) + cast(isnull(SR.HudIn,0) as char(1)) + cast(isnull(temp1.DocCount,0) as char(1)) as HudDocsFlag, 
	Case cast(isnull(SR.DocsIn,0) as char(1)) + cast(isnull(SR.HudIn,0) as char(1)) + cast(isnull(temp1.DocCount,0) as char(1))
		When '001' then 'Loan Docs and Title are not in. Other docs exist.'
		When '011' then 'Loan Docs are not in. Title is in. Other docs exist.'
		When '101' then 'Loan Docs are in. Title is not in. Other docs exist.'
		When '111' then 'Loan Docs and Title are in. Other docs exist.'
		When '000' then 'Loan Docs and Title are not in.'
		When '010' then 'Loan Docs are not in. Title is in.'
		When '100' then 'Loan Docs are in. Title is not in.'
		When '110' then 'Loan Docs and Title are in.'
		else 'Desc error.'
	end as HudDocsFlagDesc,
	isnull(SR.Refused,0) as Refused, 
	isnull(SR.NoShow,0) as NoShow,
	
	Isnull(convert(varchar(20),SR.InvoiceCreated,101),'') as InvoiceCreated,
	Isnull(convert(varchar(20),SR.Invoiced,101),'') as Invoiced,
	Isnull(convert(varchar(20),SR.InvoicePaid,101),'') as InvoicePaid,
	Isnull(convert(varchar(20),SR.NotaryPaid,101),'') as NotaryPaid,
	--Case When SR.InvoiceCreated is Null then 0 else 1 end as InvoiceCreated, 
	--Case When SR.Invoiced is Null then 0 else 1 end as Invoiced, 
	--Case When SR.InvoicePaid is Null then 0 else 1 end as CustomerPaid, 
	--Case When SR.NotaryPaid is Null then 0 else 1 end as NotaryPaid
	--SR.RequestID as SystemRequestID,
	isnull(US.StaffInitials,'') as StaffInitials

From dbo.ctbl_SigningRequests SR with(nolock)
	left outer join dbo.ctbl_SigningRequestsB SRB with(nolock)
		on SR.RequestID = SRB.RequestID
	Left Outer Join dbo.ctbl_SigningRequestStatus SRS with(nolock)
		ON SR.SigningStatusID = SRS.SigningStatusID
	Left Outer Join dbo.ctbl_UserData UD with(nolock)
		ON SR.AssignedAgent = UD.UserID
	left Outer Join dbo.Users US with(nolock)
		on US.UserID = SR.AssignedStaffID
	Left Outer Join dbo.Users Users with(nolock)
		ON SR.AssignedAgent = Users.UserID
	Left Outer Join dbo.ctbl_AgentCustomData ACD with(nolock)--stan added 10/26/16
		ON SR.AssignedAgent = ACD.UserID	--stan added 10/26/16
		and ACD.PortalID = @PortalID --stan added 10/26/16	
	Left Outer Join dbo.ctbl_UserData CustInfo with(nolock)
		ON SR.UserID = CustInfo.UserID
	Left Outer Join ctbl_PortalData with(nolock)
		On ctbl_PortalData.PortalID = @PortalID
	Left Outer Join (
		Select ctbl_Docs.RequestID, Case when Count(ctbl_Docs.DocID) > 0 then 1 else 0 end as DocCount from ctbl_Docs  with(nolock)
		Where ctbl_Docs.PortalID = @PortalID 
		and ctbl_Docs.LoanDocs = 0 and ctbl_Docs.TitleDocs = 0
		Group by ctbl_Docs.RequestID
	) as temp1 ON SR.RequestID = temp1.RequestID 
Where 
	--SR.PortalID = @PortalID
	--and SR.InActiveDate is null
	--and SR.BorrowerLastName like IsNull(nullif('%'+@txtBorrowerLastName+'%','%%'),SR.BorrowerLastName)
 --   and SR.SigningStatusID Between IsNull(Nullif(@Status1,-1),SR.SigningStatusID) and IsNull(NullIf(@Status2,-1),SR.SigningStatusID)
 --   and SR.SigningDate >= IsNull(@BegDate2,SR.SigningDate) and SR.SigningDate < IsNull(@EndDate2,SR.SigningDate) + 1
 --   and SR.DeleteDate Is Null
 --   and SR.UserID = IsNull(nullif(@ddlCustomerList,0),SR.UserID)
	--and isnull(Users.FirstName,'') like IsNull(nullif('%'+@txtAgentName_First+'%','%%'),isnull(Users.FirstName,''))
	--and isnull(Users.LastName,'') like IsNull(nullif('%'+@txtAgentName_Last+'%','%%'),isnull(Users.LastName,''))

	SR.PortalID = @PortalID
	and SR.InActiveDate is null
	and SR.DeleteDate Is Null
	and 
		(
			@txtBorrowerLastName = ''
			or
			SR.BorrowerLastName like '%'+@txtBorrowerLastName+'%'
		)
	and
		(
			@RequestSeqID = 0
			or
			SR.RequestSeqID = @RequestSeqID
		)
    and (
			@AgentProfileID = 0
			or 
			SR.AssignedAgent = @AgentProfileID
		)
	and 
		SR.SigningStatusID between @StatusCodeIDBegin and @StatusCodeIDEnd
	and 
		SR.RequestDate >=@Date_From and SR.RequestDate <= @Date_To --12/28/16 change signing date to request date to get date request was added.
	and (
			@UseCustomerSearch = 0 
			or 
			SR.UserID in (select CustomerID from #CustomerIDs)
		) 
	and (
			@txtAgentName_First = '' 
			or Users.FirstName like '%' + @txtAgentName_First + '%'
		)
	and (
			@txtAgentName_Last = '' 
			or Users.LastName like '%' + @txtAgentName_Last + '%'
		)	
Order by StatusOrder, SR.SigningDate, SR.RequestSeqID
GO
