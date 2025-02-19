# 1) Query SQL Server to get the latest build number from a table (e.g., BuildHistory).
# 2) Determine the next build number by incrementing the latest retrieved version.
# 3) Create a new folder in db_mods/, using the determined build number (e.g., db_mods/0.0.2/DB/).
# 4) Allow manual build versions (e.g., if the user manually sets 0.0.5, don’t enforce sequence checks).
# 5) Copy all staged files under DB/, preserving folder structure.

create table dbo.BuildHistory
(
	 Id Int identity(1,1)
	,BuildVersion VARCHAR(10)
	,BuildLog NVARCHAR(MAX)
)