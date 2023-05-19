# Weatherman 
is a simple tool build on top of [strom_api](https://github.com/willyfromtheblock/strom_api "strom_api") and the [open-meteo](https://open-meteo.com/ "open-meteo") API.

It allows you to define a location with lat and long coordinates for which it will get a weather forecast for the next 24 hours from **open-meteo**. It then queries **strom_api** for the respective electricity prices in **Spain** (currently only peninsular.)

Prices will now be ranked by temperature, so you can get the lowest energy price at the highest outside temperature, ideal for **heat pump** applications.

The number of time slots is configurable, see **docker-compose.yml**. 

Work in progress.


# Run your own
### Prerequisites
- docker-compose

### Configure
- adapt environment in **docker-compose.yaml** accordingly or create a **docker-compose.override.yaml** file
- **do not change TZ**
- Adapt **RAPID_API_KEY** and **_HOST** accordingly
- **API_SECRET** is required by default. Incoming queries to the REST server need to provide this as **API_KEY** in the request header.

### Setup
- execute `./deploy.sh`
- Default port is 3002. **Congratulations**. You now have a running weatherman on this port. 
It can easily be reverse proxied if need be.

### Updating
- executing `./deploy.sh `will always rebuild the main branch of this repository and restart the container