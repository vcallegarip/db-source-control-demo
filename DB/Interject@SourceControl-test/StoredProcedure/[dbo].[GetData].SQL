DROP PROCEDURE IF EXISTS [dbo].[GetData]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetData]
AS
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 1 as [OrderId], 'Coca-cola' as [ItemName] UNION ALL
	SELECT 2 as [OrderId], 'Pepsi' as [ItemName]

END
GO
