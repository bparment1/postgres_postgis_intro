
#Load data into PostgreSQL from ESRI shape file 
##Connect
con <- dbConnect(PostgreSQL(), dbname = 'supplychaincommitments',user='supplychaincommitments',password='34gj36fd', host = 'sesync-postgis01.research.sesync.org')

#
psql -h sesync-postgis01.research.sesync.org -d supplychaincommitments -U supplychaincommitments

##Here we are reading in the shapefile data into the database 
#sqlcommand=c("shp2pgsql -s 4326 -c -I /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits | psql -U supplychaincommitments -d supplychaincommitments")

sqlcommand=c("shp2pgsql -s 4326 /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits")

##Access the database
dbSendQuery(con,sqlcommand)


Do above in one step
shp2pgsql -s 4326 neighborhoods public.neighborhoods | psql -h myserver -d mydb -U myuser

Load data into PostgreSQL from ESRI shape file MA stateplane feet to geography
shp2pgsql -G -s 2249:4326 neighborhoods public.neighborhoods > neighborhoods_geog.sql
psql -h myserver -d mydb -U myuser -f neighborhoods_geog.sql

Sample linux sh script to load tiger 2007 massachusetts edges and landmark points
TMPDIR="/gis_data/staging"
STATEDIR="/gis_data/25_MASSACHUSETTS"
STATESCHEMA="ma"
DB="tiger"
USER_NAME="tigeruser"
cd $STATEDIR
#unzip files into temp directory
for z in */*.zip; do unzip -o -d $TMPDIR $z; done 
for z in *.zip; do unzip -o -d $TMPDIR $z; done


#loop thru pointlm and edges county tables and append to respective ma.pointlm ma.edges tables
for t in pointlm edges;
do
for z in *${t}.dbf;
do 
shp2pgsql  -s 4269 -g the_geom_4269 -S -W "latin1" -a $z ${STATE_SCHEMA}.${t} | psql -d $DB -U $USER_NAME;  
done
done

# disconnect from the PostgreSQL server
#dbDisconnect(con)
