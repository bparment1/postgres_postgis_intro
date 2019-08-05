library(sf)
library(raster)
library(RPostgreSQL)

#Cannot connect from ssh.sesync.org
#bparmentier@sshgw02:~$ psql -h sesync-postgis01.research.sesync.org -U supplychaincommitments
#-bash: psql: command not found

#Can connect from laptop:
#bparmentier@bps:~/z_drive/Data/git_repo$ psql -h sesync-postgis01.research.sesync.org -U supplychaincommitments
#Password for user supplychaincommitments: 
#  psql (9.5.7, server 9.3.17)
#SSL connection (protocol: TLSv1.2, cipher: DHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
#Type "help" for help.
#
#supplychaincommitments=> 
 
#bparmentier@bps:~/z_drive/Data/projects/supplychaincommitments$ shp2pgsql -s 4326 -c -I /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits | psql -h sesync-postgis01.research.sesync.org -U supplychaincommitments -d supplychaincommitments
#The program 'shp2pgsql' is currently not installed. You can install it by typing:
#  sudo apt install postgis
#
#[1]+  Stopped                 shp2pgsql -s 4326 -c -I /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits | psql -h sesync-postgis01.research.sesync.org -U supplychaincommitments -d supplychaincommitments


### Local data with postgis installed!
#shp2pgsql -s 4326 -I /home/bparmentier/z_drive/Data/projects/supplychaincommitments/data/BRA_adm1.shp | psql -h sesync-postgis01.research.sesync.org -U supplychaincommitments -d supplychaincommitments
#Password for user supplychaincommitments: Shapefile type: Polygon
#Postgis type: MULTIPOLYGON[2]

#SET
#SET
#BEGIN
#CREATE TABLE
#ALTER TABLE
#addgeometrycolumn                     
#----------------------------------------------------------
#  public.bra_adm1.geom SRID:4326 TYPE:MULTIPOLYGON DIMS:2 
#(1 row)
#
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#INSERT 0 1
#CREATE INDEX
#COMMIT
#ANALYZE


############## In R ###############

#Load data into PostgreSQL from ESRI shape file 
##Connect
con <- dbConnect(PostgreSQL(), 
                 dbname = 'supplychaincommitments',
                 user='supplychaincommitments',
                 password='34gj36fd', 
                 host = 'sesync-postgis01.research.sesync.org')

##Here we are reading in the shapefile data into the database 
#sqlcommand=c("shp2pgsql -s 4326 -c -I /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits | psql -U supplychaincommitments -d supplychaincommitments")

in_filename <- "/nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp" 

## Read in as sp object:
BRstate_sp <- readOGR(dsn=dirname(in_filename),layer=sub(".shp","",basename(in_filename)))

## Read in as sf object
BRstate_sf <- st_read(dsn=dirname(in_filename),layer=sub(".shp","",basename(in_filename)))

sqlcommand=c("shp2pgsql -s 4326 /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits | psql -U supplychaincommitments -d supplychaincommitments -h sesync-postgis01.research.sesync.org")
system(sqlcommand)

writeOGR(BRstate_sp, "PG:dbname=supplychaincommitments host=sesync-postgis01.research.sesync.org user=supplychaincommitments password=34gj36fd",  
         layer="BRA_test",layer_options = "OVERWRITE=true", driver= "PostgreSQL")

st_write(BRstate_sf, "PG:dbname=supplychaincommitments host=sesync-postgis01.research.sesync.org user=supplychaincommitments password=34gj36fd", 
         layer_options = "OVERWRITE=true")

plot(BRstate_sf)


##Access the database
sql_command <- "SELECT id_1 FROM bra_test"
results <- dbSendQuery(con,sql_command)

#################### End of script ##################################

#Useful links:
#https://rpubs.com/dgolicher/6373
#http://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg
