library(sf)
library(raster)

#Read data
setwd('/nfs/supplychaincommitments-data/SESYNC GIS Database/')


#Read data
biome_sf <- st_read(dsn="Biomes","Brazil_Biomes")
names(biome_sf)
biome_sf
plot(biome_sf$geometry) #plotting spatial data
plot(biome_sf,add=T,col="red")
BRadmin_sf <- st_read(dsn='Admin','BRA_adm2')

BRstate_sf <- st_read(dsn='Admin','BRA_adm1')
Trade<-read.csv("big5trade-1.csv")

HASC_1

#Check projections
st_crs(biome_sf)
st_crs(BRadmin_sf)
summary(BRadmin_sf)
BRadmin_sf

#Joined biomes to administrative units
BRadmin_intersects_list <- st_intersects(x=BRadmin_sf,y=biome_sf) #getting identifier of overlapping biomes
BRadmin_biomes_combined <-do.call("rbind",BRadmin_intersects_list)
#Lost 5 munis, why????? there should have been perfect overlap between biome map and admin map

dim(BRadmin_biomes_combined)

#How to change projection for shapefile if necessary
st_transform(BRadmin_sf,crs="+proj=longlat +datum=WGS84 +no_defs")

#1) for each administrative unit, find out overlapping biomes
#2) select biomes and adminstrative unit st_intersects
#3) st_area

#Dataframe that has each row here (munis, sometimes duplicates), then 
#calculate area, then add column, then reshape long to wide

BRadmin_intersection_sf <- st_intersection(x=BRadmin_sf,y=biome_sf) #getting identifier of overlapping biomes
class(BRadmin_intersection_sf)
BRadmin_intersection_sf
st_area(BRadmin_intersection_sf[1,])
