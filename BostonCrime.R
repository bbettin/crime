# https://data.cityofboston.gov/Public-Safety/Crime-Incident-Reports-July-2012-August-2015-Sourc/7cdf-6fgx

# Dependencies
dependent <- c("ggmap", "data.table", "reshape2", "ggplot2", "dplyr", "forecast", "quantmod",
               "tseries", "stats", "dynlm", "vars", "scales")
lapply(dependent, library, character.only = TRUE)

# ggmap citation
# D. Kahle and H. Wickham. ggmap: Spatial Visualization with ggplot2. The R Journal, 5(1),
# 144-161. URL http://journal.r-project.org/archive/2013-1/kahle-wickham.pdf

# Set your working directory
setwd("~/crime")

# read in the data
crimeRaw <- read.csv(file = "BostonCrime.csv", header = TRUE, sep = ",")

# split off the Lat/Long coordinates from full variable
crimeBoston <- data.frame(crimeRaw, colsplit(crimeRaw$Location, pattern = "\\,", names = c("Lat", "Long")))
crimeBoston$Lat <- as.numeric(sub(pattern = "\\(", replacement = "", x = crimeBoston$Lat))
crimeBoston$Long <- as.numeric(sub(pattern = "\\)", replacement = "", x = crimeBoston$Long))
str(crimeBoston)

# Fix the date formats
crimeBoston$FROMDATE <- as.character(crimeBoston$FROMDATE)
crimeBoston$DATE <- as.Date(crimeBoston$FROMDATE, format = "%m/%d/%Y %I:%M:%S %p")

# Change time to 24-hour clock
# crimeBoston$DATE <- as.Date(crimeBoston$FROMDATE, format = "%m/%d/%Y %H:%M:%S")

# Add month, week, day, hour formats
crimeBoston$MONTH <- as.Date(cut(crimeBoston$DATE, breaks = "month"))
crimeBoston$WEEK <- as.Date(cut(crimeBoston$DATE, breaks = "week", start.on.monday = FALSE))
crimeBoston$DAY <- as.Date(cut(crimeBoston$DATE, breaks = "day"))

# Explore crime types
unique(crimeBoston$INCIDENT_TYPE_DESCRIPTION)
barplot(prop.table(table(crimeBoston$INCIDENT_TYPE_DESCRIPTION)))
table(crimeBoston$INCIDENT_TYPE_DESCRIPTION)

# Fix repeat variables
crimeBoston$INCIDENT_TYPE_DESCRIPTION <- toupper(crimeBoston$INCIDENT_TYPE_DESCRIPTION)

# Create crime buckets
violentCrime <- c("AGGRAVATED ASSAULT", "SIMPLE ASSAULT", "DEATH INVESTIGATION", "HOMICIDE", "MANSLAUG")
sexCrimes <- c("CRIMES AGAINST CHILDREN", "SEXREG", "PROSTITUTION CHARGES", "SEX OFFENDER REGISTRATION",
               "PROSTITUTION", "RAPE AND ATTEMPTED")
propertyCrimes <- c("RESIDENTIAL BURGLARY", "ROBBERY", "COMMERCIAL BURGLARY", "PROPLOST", "OTHER LARCENY",
                    "AUTO THEFT", "VANDALISM", "LARCENY FROM MOTOR VEHICLE", "FIRE", "ARSON",
                    "PROPERTY RELATED DAMAGE", "OTHER BURGLARY")

# Subset the dataset on the buckets
violence <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% violentCrime)
violenceMonth <- as.data.frame(table(violence$MONTH))
colnames(violenceMonth) <- c("Date", "Total")
violenceMonth$Date <- as.character(violenceMonth$Date)
violenceMonth$Date <- as.Date(violenceMonth$Date, format = "%Y-%m-%d")
# Drop the last observation, as it appears to be an outlier or and incomplete observation.
violenceMonth[38,] <- NA

sex <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% sexCrimes)
sexMonth <- as.data.frame(table(sex$MONTH))
colnames(sexMonth) <- c("Date", "Total")
sexMonth$Date <- as.character(sexMonth$Date)
sexMonth$Date <- as.Date(sexMonth$Date, format = "%Y-%m-%d")
sexMonth[38,] <- NA


property <- subset(crimeBoston, INCIDENT_TYPE_DESCRIPTION %in% propertyCrimes)
propertyMonth <- as.data.frame(table(property$MONTH))
colnames(propertyMonth) <- c("Date", "Total")
propertyMonth$Date <- as.character(propertyMonth$Date)
propertyMonth$Date <- as.Date(propertyMonth$Date, format = "%Y-%m-%d")
propertyMonth[38,] <- NA
propertyMonth[37,] <- NA

# Exploratory plots
# Monthly violent crime
crimeMonth <- ggplot(violenceMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Violent Crime in Boston (JUL 2012 - JUL 2015)", 
       x = "Month", y = "Violent Crime by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "blue", colour = "red", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b", date_breaks = "3 months", date_minor_breaks = "1 month") +
  theme(plot.title = element_text(hjust = 0.5))
crimeMonth

# Sex crimes
SexCrimeMonth <- ggplot(sexMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Sex Crimes in Boston (JUL 2012 - JUL 2015)", 
       x = "Month", y = "Sex Crimes by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "blue", colour = "red", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b", date_breaks = "3 months", date_minor_breaks = "1 month") +
  theme(plot.title =  element_text(hjust = 0.5))
SexCrimeMonth

# Property Crimes
propertyCrimeMonth <- ggplot(propertyMonth, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Property Crimes in Boston (JUL 2012 - JUN 2015)", 
       x = "Month", y = "Property Crimes by Month") +
  stat_smooth(method = "lm", se = TRUE, fill = "blue", colour = "red", aes(group = 1)) + 
  scale_x_date(date_labels = "%Y %b", date_breaks = "3 months", date_minor_breaks = "1 month") +
  theme(plot.title = element_text(hjust = 0.5))
propertyCrimeMonth

# Hourly plots of the crime variables
# Work in progress
crimeHour <- ggplot(violenceHour, aes(x = Date, y = Total)) +
  geom_line(position = "identity", aes(group = 1)) +
  labs(title = "Violent Crime in Boston (JUL 2012 - JUL 2015)", 
       x = "Hour", y = "Violent Crime by Hour") +
  stat_smooth(method = "lm", se = TRUE, fill = "black", colour = "black", aes(group = 1)) + 
  scale_x_date(date_labels = "%I")
# Need to fix x-axis scale. Change trendline color. Add "," on y-axis. 
crimeHour    


# Start making some heat maps
# Create base map for Boston
BostonBase <- get_map(location = c(-71.075, 42.34), zoom = 12, maptype = "roadmap", 
                  source = "google")
BostonMap <- ggmap(BostonBase, fullpage = TRUE)

# violent crime maps 2012-2015
map1 <- ggmap(BostonBase, extent = "panel") + 
        geom_density2d(data = violence, aes(x = Long, y = Lat), size = 0.3) +
        stat_density2d(data = violence, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Violent Crime in Boston 2012-2015", x = "Longitude", y = "Latitude",
             fill = "Crime \nDensity") +
        theme(plot.title = element_text(hjust = 0.5)) +
        geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
        geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map1

# Sex crime maps
map2 <- ggmap(BostonBase, extent = "panel") +
        geom_density2d(data = sex, aes(x = Long, y = Lat), size = 0.3) +
        stat_density_2d(data = sex, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Sex Crimes in Boston 2012-2015", x = "Longitude", y = "Latitude",
              fill = "Crime \nDensity") +
        theme(plot.title = element_text(hjust = 0.5)) +
        geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
        geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map2

# Property crime maps
map3 <- ggmap(BostonBase, extent = "panel") +
        geom_density2d(data = property, aes(x = Long, y = Lat), size = 0.3) +
        stat_density_2d(data = property, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
              size = 0.01, n = 50, geom = "polygon") +
        scale_fill_gradient(low = "green", high = "red") +
        scale_alpha(range = c(0, 0.25), guide = FALSE) +
        labs(title = "Property Crimes in Boston 2012-2015", x = "Longitude",  y = "Latitude",
             fill = "Crime \nDensity") +
        theme(plot.title = element_text(hjust = 0.5)) +
        geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
        geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map3

# Violent Crime maps by year
violence2012 <- violence[violence$Year == 2012, ]
map1_2012 <- ggmap(BostonBase, extent = "panel") + 
  geom_density2d(data = violence2012, aes(x = Long, y = Lat), size = 0.3) +
  stat_density2d(data = violence2012, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Violent Crime in Boston: 2012", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map1_2012
dev.copy(png, "map1_2012.png")
dev.off()

violence2013 <- violence[violence$Year == 2013, ]
map1_2013 <- ggmap(BostonBase, extent = "panel") + 
  geom_density2d(data = violence2013, aes(x = Long, y = Lat), size = 0.3) +
  stat_density2d(data = violence2013, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Violent Crime in Boston: 2013", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map1_2013
dev.copy(png, "map1_2013.png")
dev.off()

violence2014 <- violence[violence$Year == 2014, ]
map1_2014 <- ggmap(BostonBase, extent = "panel") + 
  geom_density2d(data = violence2014, aes(x = Long, y = Lat), size = 0.3) +
  stat_density2d(data = violence2014, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Violent Crime in Boston: 2014", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map1_2014
dev.copy(png, "map1_2014.png")
dev.off()

violence2015 <- violence[violence$Year == 2015, ]
map1_2015 <- ggmap(BostonBase, extent = "panel") + 
  geom_density2d(data = violence2015, aes(x = Long, y = Lat), size = 0.3) +
  stat_density2d(data = violence2015, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Violent Crime in Boston: 2015", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map1_2015
dev.copy(png, "map1_2015.png")
dev.off()

# Sex crime maps by year
sex2012 <- sex[sex$Year == 2012, ]
map2_2012 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = sex2012, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = sex2012, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Sex Crimes in Boston: 2012", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map2_2012
dev.copy(png, "map2_2012.png")
dev.off()

sex2013 <- sex[sex$Year == 2013, ]
map2_2013 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = sex2013, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = sex2013, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Sex Crimes in Boston: 2013", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map2_2013
dev.copy(png, "map2_2013.png")
dev.off()

sex2014 <- sex[sex$Year == 2014, ]
map2_2014 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = sex2014, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = sex2014, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Sex Crimes in Boston: 2014", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map2_2014
dev.copy(png, "map2_2014.png")
dev.off()

sex2015 <- sex[sex$Year == 2015, ]
map2_2015 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = sex2015, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = sex2015, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Sex Crimes in Boston: 2015", x = "Longitude", y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map2_2015
dev.copy(png, "map2_2015.png")
dev.off()

# Property Crimes by year
property2012 <- property[property$Year == 2012, ]
map3_2012 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = property2012, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = property2012, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Property Crimes in Boston: 2012", x = "Longitude",  y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map3_2012
dev.copy(png, "map3_2012.png")
dev.off()

property2013 <- property[property$Year == 2013, ]
map3_2013 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = property2013, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = property2013, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Property Crimes in Boston: 2013", x = "Longitude",  y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map3_2013
dev.copy(png, "map3_2013.png")
dev.off()

property2014 <- property[property$Year == 2014, ]
map3_2014 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = property2014, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = property2014, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Property Crimes in Boston: 2014", x = "Longitude",  y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map3_2014
dev.copy(png, "map3_2014.png")
dev.off()

property2015 <- property[property$Year == 2015, ]
map3_2015 <- ggmap(BostonBase, extent = "panel") +
  geom_density2d(data = property2015, aes(x = Long, y = Lat), size = 0.3) +
  stat_density_2d(data = property2015, aes(x = Long, y = Lat, fill = ..level.., alpha = ..level..),
                  size = 0.01, n = 50, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0, 0.25), guide = FALSE) +
  labs(title = "Property Crimes in Boston: 2015", x = "Longitude",  y = "Latitude",
       fill = "Crime \nDensity") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = seq(-71.175, -70.00, by = .025), size = 0.25) +
  geom_hline(yintercept = seq(42.25, 42.40, by = .025), size = 0.25)
map3_2015
dev.copy(png, "map3_2015.png")
dev.off()

# Convert .png files to .gif in the command line
# convert -delay 200 -loop 0 *.png ViolentCrime.gif

# Let's build some ARIMA models
crimeBoston2 <- as.data.frame(table(violence$MONTH))
colnames(crimeBoston2) <- c("Date", "Total")

Total <- crimeBoston2[, "Total"]

model1a <- arima(Total, order=c(1,0,0)) # AR(1) 
summary(model1a)
accuracy(model1a)







