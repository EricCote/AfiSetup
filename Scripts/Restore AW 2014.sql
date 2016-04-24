RESTORE DATABASE AdventureWorks2014
   FROM DISK = 'C:\AW\AdventureWorks2014.bak'
WITH   
      MOVE 'AdventureWorks2014_Data' TO 
'C:\AW\AdventureWorks_data.mdf', 
      MOVE 'AdventureWorks2014_Log' 
TO 'C:\AW\AdventureWorks_log.ldf';
