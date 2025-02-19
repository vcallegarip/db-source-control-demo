SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_Set_GetDateNS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[_Set_GetDateNS] AS' 
END
GO
/*
    SEE ALSO... FUNCTION [dbo].[GetDateNS]

*/
ALTER PRocedure [dbo].[_Set_GetDateNS]
	 @LocalTimeOffsetInMinutes int
as

    if exists 
        (
            Select 1 
            From [dbo].[_GlobalVariables]
            Where [Name] = 'LocalTimeOffsetMinutes'
        )
    begin
        UPDATE [dbo].[_GlobalVariables] 
        Set intValue = @LocalTimeOffsetInMinutes 
        where Name = 'LocalTimeOffsetMinutes'
    end
    else
    begin
        INSERT INTO [dbo].[_GlobalVariables] 
            (Name
            , intValue) 
        values
            ('LocalTimeOffsetMinutes'
            ,@LocalTimeOffsetInMinutes) 
    end

GO
