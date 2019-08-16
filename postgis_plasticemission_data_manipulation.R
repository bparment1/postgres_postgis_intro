############### SESYNC Research Support: plasticemission ########## 
## Connecting to database an dexporting
## 
## DATE CREATED: 08/16/2019
## DATE MODIFIED: 08/16/2019
## AUTHORS: Benoit Parmentier
## PROJECT: plasticemission working group
## ISSUE: exporting csv from database
## TO DO:
##
## COMMIT: setting up connection to postgis db with password
##
## Useful links:
#https://rpubs.com/dgolicher/6373
#http://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg

###################################################
#

###### Library used

library(gtools)                              # loading some useful tools 
library(sp)                                  # Spatial pacakge with class definition by Bivand et al.
library(sf)                                  # Spatial package with OGC standard definition, spatial object as df
library(spdep)                               # Spatial pacakge with methods and spatial stat. by Bivand et al.
library(rgdal)                               # GDAL wrapper for R, spatial utilities
library(gdata)                               # various tools with xls reading, cbindX
library(raster)                              # Raster and image processing in R
library(rasterVis)                           # Raster plotting functions
library(parallel)                            # Parallelization of processes with multiple cores
library(maptools)                            # Tools and functions for sp and other spatial objects e.g. spCbind
library(maps)                                # Tools and data for spatial/geographic objects
library(plyr)                                # Various tools including rbind.fill
library(spgwr)                               # GWR method
library(rgeos)                               # Geometric, topologic library of functions
library(gridExtra)                           # Combining lattice plots
library(colorRamps)                          # Palette/color ramps for symbology
library(ggplot2)
library(lubridate)
library(dplyr)
library(lattice)
library(gplots)
library(RPostgreSQL)

#
###### Functions used in this script and sourced from other files

create_dir_fun <- function(outDir,out_suffix=NULL){
  #if out_suffix is not null then append out_suffix string
  if(!is.null(out_suffix)){
    out_name <- paste("output_",out_suffix,sep="")
    outDir <- file.path(outDir,out_name)
  }
  #create if does not exists
  if(!file.exists(outDir)){
    dir.create(outDir)
  }
  return(outDir)
}

#Used to load RData object saved within the functions produced.
load_obj <- function(f){
  env <- new.env()
  nm <- load(f, env)[1]
  env[[nm]]
}

### Other functions for later ####

#function_processing <- ".R" #PARAM 1

#script_path <- "/nfs/bparmentier-data/Data/projects/supplychaincommitments/scripts"
#script_path <- "/nfs/supplychaincommitments-data/scripts"

#source(file.path(script_path,function_processing)) #source all functions used in this script 1.

############################################################################
####################  Parameters and argument set up ###########

#in_dir <- "/nfs/supplychaincommitments-data/GIS.Data/"
out_dir <- "/nfs/PlasticEmission-data/tmp"

num_cores <- 2 #param 8 #normally I use only 1 core for this dataset but since I want to use the mclappy function the number of cores is changed to 2. If it was 1 then mclappy will be reverted back to the lapply function
create_out_dir_param=TRUE # param 9

out_suffix <-"postgis_data_08162019" #output suffix for the files and ouptut folder #param 12

### db related:
db_ini_filename <- "/nfs/bparmentier-data/.pg_service.conf" #password info
#db_name <- "plasticemission"
#db_user <- "plasticemission"
#db_hostname <- "sesync-postgis02.research.sesync.org"

##############################  START SCRIPT  ############################

######### PART 0: Set up the output dir ################

if(is.null(out_dir)){
  out_dir <- in_dir #output will be created in the input dir
  
}
#out_dir <- in_dir #output will be created in the input dir

out_suffix_s <- out_suffix #can modify name of output suffix
if(create_out_dir_param==TRUE){
  out_dir <- create_dir_fun(out_dir,out_suffix)
  setwd(out_dir)
}else{
  setwd(out_dir) #use previoulsy defined directory
}

options(scipen=999)  #remove scientific writing


### PART I: READ IN SPATIAL DATA AND QUERY #######

##Here we are reading in the shapefile data into the database 
## From the command line:
## 1) ssh to sesync
## 2) connect to database: bparmentier@sshgw02:~$ psql -h sesync-postgis02.research.sesync.org -U plasticemission
## 3) load shapefile in postgis: shp2pgsql -s 4326 -c -I /nfs/supplychaincommitments-data/GIS.Data/Admin/BRA_adm1.shp AdminUnits2

## 4) FROM R:

#Load data into PostgreSQL from ESRI shape file 
##Read in password: 
#db_password <- scan(db_ini_filename, character(), n = 1)

library(DBI)
library(RPostgres)

conn <- dbConnect(Postgres(), 
                  service = 'plasticemission')

con <- dbConnect(PostgreSQL(), 
                 dbname = db_name,
                 user = db_user,
                 password = db_password, 
                 host = db_hostname)

## Read in as sp object:
BRstate_sp <- readOGR(dsn=dirname(infile_data),layer=sub(".shp","",basename(infile_data)))

## Read in as sf object: this is the way to go
BRstate_sf <- st_read(dsn=dirname(infile_data),layer=sub(".shp","",basename(infile_data)))

#### Write a shapefile layer to the postgis database using the sp/rgdal package

sql_command <- "SELECT id_1 FROM bra_test"
results <- dbGetQuery(con, sql_command) #this is a data.frame

sql_command <- "SELECT ID_1,ISO,NAME_1 FROM bra_adm1 LIMIT 5;"
results <- dbGetQuery(con, sql_command) #this is a data.frame

#################### End of script ##################################


